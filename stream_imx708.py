#!/usr/bin/env python3
"""
stream_imx708.py — minimal MJPEG live stream for IMX708 (Camera Module 3 / 3 Wide)
on a Raspberry Pi Zero 2 W.

Run on the Pi:
    python3 stream_imx708.py

View from your laptop (same network):
    http://<pi-ip>:8080/stream.mjpg
in a browser, or in VLC: Media > Open Network Stream > that URL.
"""

import io
import time
import threading
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

from picamera2 import Picamera2
from PIL import Image

# ---------- config ----------
PORT = 8080

# Keep this modest — the Zero 2 W's CPU is doing the JPEG encode in software here.
# 1280x720 is a good balance of quality vs frame rate on this hardware.
STREAM_W, STREAM_H = 1280, 720
JPEG_QUALITY = 65
TARGET_FPS = 20


class StreamOutput:
    def __init__(self):
        self.frame = None
        self.condition = threading.Condition()

    def push(self, jpeg_bytes: bytes):
        with self.condition:
            self.frame = jpeg_bytes
            self.condition.notify_all()


output = StreamOutput()


class MJPEGHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/", "/stream.mjpg"):
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=FRAME")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        try:
            while True:
                with output.condition:
                    output.condition.wait(timeout=5.0)
                    frame = output.frame
                if frame is None:
                    continue
                self.wfile.write(b"--FRAME\r\n")
                self.send_header("Content-Type", "image/jpeg")
                self.send_header("Content-Length", str(len(frame)))
                self.end_headers()
                self.wfile.write(frame)
                self.wfile.write(b"\r\n")
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass

    def log_message(self, *a):
        pass


def preview_loop(cam: Picamera2):
    period = 1.0 / TARGET_FPS
    while True:
        t0 = time.perf_counter()
        frame = cam.capture_array("main")  # RGB888-in-memory (BGR888 config below)
        img = Image.fromarray(frame)
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=JPEG_QUALITY)
        output.push(buf.getvalue())
        dt = time.perf_counter() - t0
        if dt < period:
            time.sleep(period - dt)


def main():
    cam = Picamera2()
    config = cam.create_video_configuration(
        main={"size": (STREAM_W, STREAM_H), "format": "BGR888"},
        controls={
            "FrameRate": TARGET_FPS,
            "AeEnable": True,
            "AwbEnable": True,
            "AfMode": 2,     # continuous autofocus (IMX708 supports PDAF)
        },
        buffer_count=2,
    )
    cam.configure(config)
    cam.start()
    print(f"Camera started: {STREAM_W}x{STREAM_H}")

    threading.Thread(target=preview_loop, args=(cam,), daemon=True).start()

    server = ThreadingHTTPServer(("0.0.0.0", PORT), MJPEGHandler)
    print(f"Streaming at http://0.0.0.0:{PORT}/stream.mjpg")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        cam.stop()


if __name__ == "__main__":
    main()
