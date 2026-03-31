#!/usr/bin/env python3
"""
retinex_control.py
CDC ACM serial control daemon for Retinex ROP Camera.
Bridges /dev/ttyGS0 (USB serial from Windows) <-> /tmp/retinex_ctrl.sock
(Unix socket to retinex_stream.py).

Protocol (text lines, newline-terminated):
  Windows -> Pi:  CMD:CAPTURE
                  CMD:BRIGHTNESS:<0-100>
  Pi -> Windows:  EVT:CAPTURED:/path/to/image.jpg
                  EVT:BRIGHTNESS:<0-100>
                  EVT:BTN_PRESSED
                  EVT:STATUS:ready

Physical capture button (optional): GPIO17, active-low with internal pull-up.
"""

import os
import sys
import socket
import select
import threading
import time
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("retinex_control")

SERIAL_PORT = "/dev/ttyGS0"           # CDC ACM gadget serial
CTRL_SOCK   = "/tmp/retinex_ctrl.sock" # Unix socket to retinex_stream.py
BUTTON_PIN  = 17                       # BCM GPIO for physical capture button
BUTTON_DEBOUNCE_S = 0.3

# ── Serial helpers ────────────────────────────────────────────────

class SerialPort:
    """Thin wrapper around the CDC ACM gadget tty."""

    def __init__(self, path):
        self._path = path
        self._fd   = None
        self._buf  = b""

    def open(self):
        # Open in raw binary mode; CDC ACM over USB doesn't use baud rate
        self._fd = open(self._path, "rb+", buffering=0)
        # Put tty in raw mode via termios
        import termios, tty
        tty.setraw(self._fd.fileno())
        log.info("Serial port %s opened", self._path)

    def close(self):
        if self._fd:
            try:
                self._fd.close()
            except Exception:
                pass
            self._fd = None

    def write_line(self, text: str):
        try:
            self._fd.write((text + "\n").encode())
        except Exception as e:
            log.warning("Serial write error: %s", e)

    def readline(self, timeout=1.0) -> str:
        """Read one newline-terminated line. Returns '' on timeout."""
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            r, _, _ = select.select([self._fd], [], [], 0.1)
            if r:
                chunk = self._fd.read(256)
                if chunk:
                    self._buf += chunk
            if b"\n" in self._buf:
                idx = self._buf.index(b"\n")
                line = self._buf[:idx].decode(errors="replace").strip()
                self._buf = self._buf[idx + 1:]
                return line
        return ""


# ── Stream socket helper ──────────────────────────────────────────

def _stream_cmd(command: str) -> str:
    """Send a command to retinex_stream.py via CTRL_SOCK. Returns response."""
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(CTRL_SOCK)
        s.sendall((command + "\n").encode())
        resp = b""
        while b"\n" not in resp:
            chunk = s.recv(256)
            if not chunk:
                break
            resp += chunk
        s.close()
        return resp.decode(errors="replace").strip()
    except Exception as e:
        log.warning("stream_cmd %r failed: %s", command, e)
        return f"ERR:{e}"


# ── GPIO button (optional) ────────────────────────────────────────

def _start_button_monitor(on_press):
    """Monitor GPIO17 for a physical capture button (active-low)."""
    try:
        import gpiozero
        btn = gpiozero.Button(BUTTON_PIN, pull_up=True, bounce_time=BUTTON_DEBOUNCE_S)
        btn.when_pressed = on_press
        log.info("GPIO button monitor active on BCM%d", BUTTON_PIN)
    except Exception:
        try:
            import RPi.GPIO as GPIO
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

            def _thread():
                last = time.monotonic()
                while True:
                    if GPIO.input(BUTTON_PIN) == GPIO.LOW:
                        now = time.monotonic()
                        if now - last > BUTTON_DEBOUNCE_S:
                            last = now
                            on_press()
                    time.sleep(0.05)

            threading.Thread(target=_thread, daemon=True).start()
            log.info("RPi.GPIO button monitor active on BCM%d", BUTTON_PIN)
        except Exception as e:
            log.info("No GPIO button monitor (library not available): %s", e)


# ── Main control loop ─────────────────────────────────────────────

class RetinexControl:
    def __init__(self):
        self._serial = SerialPort(SERIAL_PORT)

    def _handle_cmd(self, cmd: str):
        """Parse and dispatch a command received from Windows."""
        log.info("CMD received: %r", cmd)

        if cmd == "CMD:CAPTURE":
            resp = _stream_cmd("CAPTURE")
            # resp is "CAPTURED:/path/to/file.jpg"
            self._serial.write_line(f"EVT:{resp}")

        elif cmd.startswith("CMD:BRIGHTNESS:"):
            try:
                val = int(cmd.split(":", 2)[2])
                resp = _stream_cmd(f"BRIGHTNESS:{val}")
                self._serial.write_line(f"EVT:BRIGHTNESS:{val}")
            except (ValueError, IndexError) as e:
                log.warning("Bad brightness command: %s", e)

        else:
            log.warning("Unknown command: %r", cmd)

    def _on_button_press(self):
        """Physical button pressed — trigger capture and notify Windows."""
        log.info("Physical button pressed")
        self._serial.write_line("EVT:BTN_PRESSED")
        resp = _stream_cmd("CAPTURE")
        self._serial.write_line(f"EVT:{resp}")

    def run(self):
        # Wait for CDC ACM device to appear
        for _ in range(60):
            if os.path.exists(SERIAL_PORT):
                break
            log.info("Waiting for %s ...", SERIAL_PORT)
            time.sleep(2)
        else:
            log.error("Serial port %s did not appear", SERIAL_PORT)
            sys.exit(1)

        self._serial.open()
        _start_button_monitor(self._on_button_press)

        # Signal ready
        self._serial.write_line("EVT:STATUS:ready")
        log.info("Control daemon ready")

        # Wait for retinex_stream.py socket to be available
        for _ in range(30):
            if os.path.exists(CTRL_SOCK):
                break
            time.sleep(1)

        # Main command loop
        while True:
            try:
                line = self._serial.readline(timeout=1.0)
                if line:
                    self._handle_cmd(line)
            except Exception as e:
                log.error("Serial error: %s — reopening", e)
                self._serial.close()
                time.sleep(2)
                try:
                    self._serial.open()
                except Exception as e2:
                    log.error("Reopen failed: %s", e2)
                    time.sleep(5)


if __name__ == "__main__":
    RetinexControl().run()
