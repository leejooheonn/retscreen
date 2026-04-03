#!/usr/bin/env python3
"""
receive_image.py — receives raw Bayer frames from RPi Zero 2W via TCP,
applies full ISP pipeline (black level, ALSC, AWB, CCM, gamma), and saves.

Usage: python receive_image.py [--port 9999] [--width 6944] [--height 6944]
                               [--out frame.png] [--loop] [--timestamp] [--save-raw]
                               [--r-gain 2.278] [--b-gain 1.319]

Pi sends an optional "RETINEX:r_gain=X,b_gain=Y\n" header before raw bytes.
If present, those gains are used for AWB; otherwise falls back to --r-gain/--b-gain.
"""

import socket
import argparse
import numpy as np
import cv2
import sys
import time
import os
from pathlib import Path
from datetime import datetime

# Fix \r overwrite on Windows PowerShell
if os.name == "nt":
    try:
        import ctypes
        ctypes.windll.kernel32.SetConsoleMode(
            ctypes.windll.kernel32.GetStdHandle(-11), 7
        )
    except Exception:
        pass

# ── ISP constants from /usr/share/libcamera/ipa/rpi/vc4/ov64a40.json ────────

# Black level: 4096 in 16-bit → 64 in 10-bit (4096 >> 6)
BLACK_LEVEL = 64

# Color Correction Matrices per color temperature.
# Each row = output R/G/B channel; columns = input R/G/B.
# Apply as: out_rgb = ccm @ in_rgb  (or in_row @ ccm.T for (N,3) arrays).
CCM_DATA = {
    2300: np.array([[ 1.77644, -0.14825, -0.62819],
                    [-0.25816,  1.66348, -0.40532],
                    [-0.21633, -1.95132,  3.16765]], dtype=np.float32),
    2700: np.array([[ 1.53605,  0.03047, -0.56652],
                    [-0.27159,  1.78525, -0.51366],
                    [-0.13581, -1.22128,  2.35709]], dtype=np.float32),
    3000: np.array([[ 1.72928, -0.18819, -0.54108],
                    [-0.44398,  2.04756, -0.60358],
                    [-0.13203, -0.94711,  2.07913]], dtype=np.float32),
    4000: np.array([[ 1.69895, -0.23055, -0.46841],
                    [-0.33934,  1.80391, -0.46456],
                    [-0.13902, -0.75385,  1.89287]], dtype=np.float32),
    4150: np.array([[ 2.08494, -0.68698, -0.39796],
                    [-0.37928,  1.78795, -0.40867],
                    [-0.11537, -0.74686,  1.86223]], dtype=np.float32),
    6500: np.array([[ 1.69813, -0.27304, -0.42509],
                    [-0.23364,  1.87586, -0.64221],
                    [-0.07587, -0.62348,  1.69935]], dtype=np.float32),
}

# AWB ct_curve: (color_temp, R/G ratio, B/G ratio)
# Used to estimate CT from measured R gain so we can pick the right CCM.
CT_CURVE = [
    (2300, 1.0522, 0.4091),
    (2700, 0.7884, 0.4327),
    (3000, 0.7597, 0.4421),
    (4000, 0.5972, 0.5404),
    (4150, 0.5598, 0.5779),
    (6500, 0.4388, 0.7582),
]

# Luminance lens-shading correction table: 12 rows × 16 cols (covers full sensor).
# Values are gain factors to correct lens falloff — center ≈1.0, corners ≈3.8.
LUMINANCE_LUT = [
    3.811, 3.611, 3.038, 2.632, 2.291, 2.044, 1.967, 1.957, 1.957, 1.957, 2.009, 2.222, 2.541, 2.926, 3.455, 3.652,
    3.611, 3.135, 2.636, 2.343, 2.044, 1.846, 1.703, 1.626, 1.626, 1.671, 1.796, 1.983, 2.266, 2.549, 3.007, 3.455,
    3.135, 2.781, 2.343, 2.044, 1.831, 1.554, 1.411, 1.337, 1.337, 1.379, 1.502, 1.749, 1.983, 2.266, 2.671, 3.007,
    2.903, 2.538, 2.149, 1.831, 1.554, 1.401, 1.208, 1.145, 1.145, 1.183, 1.339, 1.502, 1.749, 2.072, 2.446, 2.801,
    2.812, 2.389, 2.018, 1.684, 1.401, 1.208, 1.139, 1.028, 1.028, 1.109, 1.183, 1.339, 1.604, 1.939, 2.309, 2.723,
    2.799, 2.317, 1.948, 1.606, 1.327, 1.139, 1.028, 1.019, 1.001, 1.021, 1.109, 1.272, 1.531, 1.869, 2.246, 2.717,
    2.799, 2.317, 1.948, 1.606, 1.327, 1.139, 1.027, 1.006, 1.001, 1.007, 1.109, 1.272, 1.531, 1.869, 2.246, 2.717,
    2.799, 2.372, 1.997, 1.661, 1.378, 1.184, 1.118, 1.019, 1.012, 1.103, 1.158, 1.326, 1.589, 1.926, 2.302, 2.717,
    2.884, 2.507, 2.116, 1.795, 1.511, 1.361, 1.184, 1.118, 1.118, 1.158, 1.326, 1.461, 1.726, 2.056, 2.434, 2.799,
    3.083, 2.738, 2.303, 1.989, 1.783, 1.511, 1.361, 1.291, 1.291, 1.337, 1.461, 1.726, 1.942, 2.251, 2.657, 2.999,
    3.578, 3.083, 2.589, 2.303, 1.989, 1.783, 1.637, 1.563, 1.563, 1.613, 1.743, 1.942, 2.251, 2.537, 2.999, 3.492,
    3.764, 3.578, 2.999, 2.583, 2.237, 1.986, 1.913, 1.905, 1.905, 1.905, 1.962, 2.196, 2.525, 2.932, 3.492, 3.659,
]

_FULL_SENSOR_W = 9248   # OV64A40 full-resolution sensor width

# ── ISP helpers ──────────────────────────────────────────────────────────────

def _estimate_ct(r_gain: float) -> int:
    """Estimate scene color temperature from R AWB gain (G/R)."""
    r_ratio = 1.0 / max(r_gain, 1e-6)
    if r_ratio >= CT_CURVE[0][1]:
        return CT_CURVE[0][0]
    if r_ratio <= CT_CURVE[-1][1]:
        return CT_CURVE[-1][0]
    for i in range(len(CT_CURVE) - 1):
        ct1, rg1, _ = CT_CURVE[i]
        ct2, rg2, _ = CT_CURVE[i + 1]
        if rg2 <= r_ratio <= rg1:
            t = (rg1 - r_ratio) / (rg1 - rg2)
            return int(ct1 + t * (ct2 - ct1))
    return 6500


def _interpolate_ccm(ct: int) -> np.ndarray:
    """Linear interpolation of CCM at given color temperature."""
    cts = sorted(CCM_DATA.keys())
    if ct <= cts[0]:
        return CCM_DATA[cts[0]]
    if ct >= cts[-1]:
        return CCM_DATA[cts[-1]]
    for i in range(len(cts) - 1):
        if cts[i] <= ct <= cts[i + 1]:
            t = (ct - cts[i]) / (cts[i + 1] - cts[i])
            return (1.0 - t) * CCM_DATA[cts[i]] + t * CCM_DATA[cts[i + 1]]
    return CCM_DATA[6500]


_alsc_cache: dict = {}

def _build_alsc_map(h: int, w: int) -> np.ndarray:
    """
    Build lens-shading correction map for the received image dimensions.
    The LUT covers the full 9248-wide sensor; if w < 9248 it is a center crop.
    Returns float32 array shape (h, w) with per-pixel gain factors.
    """
    key = (h, w)
    if key in _alsc_cache:
        return _alsc_cache[key]

    lut = np.array(LUMINANCE_LUT, dtype=np.float32).reshape(12, 16)
    # Resize to full sensor dimensions then crop to the received region
    lut_full = cv2.resize(lut, (_FULL_SENSOR_W, h), interpolation=cv2.INTER_LINEAR)
    start_x = (_FULL_SENSOR_W - w) // 2 if w < _FULL_SENSOR_W else 0
    alsc = np.ascontiguousarray(lut_full[:, start_x:start_x + w])
    _alsc_cache[key] = alsc
    return alsc


# ── Core processing ───────────────────────────────────────────────────────────

def progress(msg: str):
    sys.stdout.write(f"\r{msg:<80}")
    sys.stdout.flush()


def receive_raw(port: int, expected_bytes: int) -> tuple[bytes, float, dict]:
    """
    Listen for one TCP connection, receive all data until EOF.
    If the first line starts with "RETINEX:", parse it as metadata (r_gain, b_gain)
    and strip it from the returned payload.
    Returns (raw_bytes, transfer_seconds, metadata_dict).
    """
    print(f"[*] Listening on port {port}  (Ctrl+C to quit)", flush=True)
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.settimeout(1.0)
    srv.bind(("0.0.0.0", port))
    srv.listen(1)

    conn = None
    while conn is None:
        try:
            conn, addr = srv.accept()
        except socket.timeout:
            continue

    print(f"[*] Connection from {addr[0]}:{addr[1]}", flush=True)
    conn.settimeout(10.0)

    data = bytearray()
    t_start = time.perf_counter()
    mb_total = expected_bytes / 1_048_576

    try:
        with conn:
            while True:
                try:
                    chunk = conn.recv(65536)
                except socket.timeout:
                    sys.stdout.write("\n")
                    print("[!] Connection timed out mid-transfer", file=sys.stderr)
                    break
                if not chunk:
                    break
                data.extend(chunk)
                elapsed = time.perf_counter() - t_start
                mb_recv = len(data) / 1_048_576
                mbps = mb_recv / elapsed if elapsed > 0 else 0
                pct = mb_recv / mb_total * 100
                progress(f"[recv]  {mb_recv:.1f} / {mb_total:.1f} MB  ({pct:.0f}%)  {mbps:.1f} MB/s  {elapsed:.1f}s")
    finally:
        srv.close()

    transfer_time = time.perf_counter() - t_start
    sys.stdout.write("\n")
    sys.stdout.flush()

    # Parse optional metadata header sent by camera_daemon.py
    meta: dict = {}
    payload = bytes(data)
    if payload.startswith(b"RETINEX:"):
        nl = payload.index(b"\n")
        header_str = payload[8:nl].decode(errors="ignore")
        for kv in header_str.split(","):
            if "=" in kv:
                k, v = kv.split("=", 1)
                try:
                    meta[k.strip()] = float(v.strip())
                except ValueError:
                    meta[k.strip()] = v.strip()  # keep string values (e.g. format=jpeg)
        payload = payload[nl + 1:]

    return payload, transfer_time, meta


def unpack_10bit(raw: bytes, width: int, height: int) -> np.ndarray:
    """Unpack CSI-2 10-bit packed Bayer data to uint16 array (h, w)."""
    row_bytes = width * 10 // 8
    expected_tight = row_bytes * height
    total = len(raw)

    arr = np.frombuffer(raw, dtype=np.uint8)

    if total > expected_tight:
        # Strided data — strip row padding
        stride = total // height
        arr = arr.reshape(height, stride)[:, :row_bytes].copy().ravel()
    else:
        arr = arr[:expected_tight]

    arr = arr.reshape(-1, 5)
    out = np.zeros((arr.shape[0], 4), dtype=np.uint16)
    out[:, 0] = (arr[:, 0].astype(np.uint16) << 2) | (arr[:, 4] & 0x03)
    out[:, 1] = (arr[:, 1].astype(np.uint16) << 2) | ((arr[:, 4] >> 2) & 0x03)
    out[:, 2] = (arr[:, 2].astype(np.uint16) << 2) | ((arr[:, 4] >> 4) & 0x03)
    out[:, 3] = (arr[:, 3].astype(np.uint16) << 2) | ((arr[:, 4] >> 6) & 0x03)
    return out.reshape(height, width)


def debayer(bayer: np.ndarray, r_gain: float = 2.278, b_gain: float = 1.319) -> np.ndarray:
    """
    Full ISP pipeline for OV64A40 raw Bayer (SRGGB10 / RGGB):
      1. Black level subtraction (64 in 10-bit)
      2. Lens-shading correction (ALSC luminance LUT from ov64a40.json)
      3. AWB channel gains (R × r_gain, B × b_gain, from Pi capture metadata)
      4. Demosaic to BGR
      5. Color correction matrix (CCM, interpolated by estimated CT)
      6. sRGB gamma (x ^ 1/2.2)
    """
    h, w = bayer.shape

    # 1. Black level
    bayer_f = bayer.astype(np.float32) - BLACK_LEVEL
    np.clip(bayer_f, 0.0, None, out=bayer_f)

    # 2. Lens-shading correction
    bayer_f *= _build_alsc_map(h, w)

    # 3. AWB gains in Bayer domain (RGGB: R=even-row/even-col, B=odd-row/odd-col)
    bayer_f[0::2, 0::2] *= r_gain
    bayer_f[1::2, 1::2] *= b_gain

    # 4. Normalize to [0,1] and demosaic
    signal_max = 1023.0 - BLACK_LEVEL  # 959.0
    np.clip(bayer_f / signal_max, 0.0, 1.0, out=bayer_f)
    bayer8 = (bayer_f * 255.0).astype(np.uint8)
    rgb = cv2.cvtColor(bayer8, cv2.COLOR_BayerBG2RGB)  # actual phase is BGGR → RGB output

    # 5. CCM in linear RGB domain
    ct = _estimate_ct(r_gain)
    ccm = _interpolate_ccm(ct)
    rgb_f = rgb.astype(np.float32) / 255.0
    rgb_f = np.clip(rgb_f.reshape(-1, 3) @ ccm.T, 0.0, 1.0).reshape(h, w, 3)

    # 6. sRGB gamma
    np.power(rgb_f, 1.0 / 2.2, out=rgb_f)
    rgb = (rgb_f * 255.0).astype(np.uint8)
    return cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)  # BGR for cv2.imwrite


def make_output_path(base: Path, frame_num: int, use_timestamp: bool) -> Path:
    if use_timestamp:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        return base.with_name(f"{base.stem}_{ts}{base.suffix}")
    elif frame_num > 1:
        return base.with_name(f"{base.stem}_{frame_num:04d}{base.suffix}")
    return base


def process_frame(raw: bytes, width: int, height: int, out_path: Path,
                  transfer_time: float, frame_num: int,
                  use_timestamp: bool, save_raw: bool,
                  meta: dict, r_gain_default: float, b_gain_default: float):
    expected = width * height * 10 // 8
    mb_received = len(raw) / 1_048_576
    mbps = mb_received / transfer_time if transfer_time > 0 else 0

    if len(raw) < expected:
        print(f"[!] Warning: got {len(raw):,} bytes, expected {expected:,}")

    r_gain = meta.get("r_gain", r_gain_default)
    b_gain = meta.get("b_gain", b_gain_default)
    ct = _estimate_ct(r_gain)
    src = "Pi metadata" if "r_gain" in meta else "default/arg"
    print(f"[*] Transfer:  {mb_received:.1f} MB  {transfer_time:.2f}s  {mbps:.1f} MB/s")

    # Pi sent hardware-ISP JPEG — save directly, skip raw ISP pipeline
    if meta.get("format") == "jpeg":
        out = make_output_path(out_path, frame_num, use_timestamp)
        out.write_bytes(raw)
        file_mb = out.stat().st_size / 1_048_576
        print(f"[+] Saved: {out}  ({file_mb:.1f} MB)")
        return

    print(f"[*] AWB gains: r={r_gain:.3f}  b={b_gain:.3f}  CT≈{ct}K  ({src})")

    out = make_output_path(out_path, frame_num, use_timestamp)

    if save_raw:
        raw_out = out.with_suffix(".raw")
        raw_out.write_bytes(raw)
        print(f"[*] Raw saved: {raw_out}")

    t0 = time.perf_counter()
    print("[*] Unpacking...", end="", flush=True)
    bayer = unpack_10bit(raw, width, height)

    print(f"  ISP pipeline (CT≈{ct}K)...", end="", flush=True)
    bgr = debayer(bayer, r_gain=r_gain, b_gain=b_gain)
    t_proc = time.perf_counter() - t0

    cv2.imwrite(str(out), bgr)
    file_mb = out.stat().st_size / 1_048_576
    print(f"  done ({t_proc:.2f}s)")
    print(f"[+] Saved: {out}  ({file_mb:.1f} MB)")
    print(f"[+] Total: {transfer_time + t_proc:.2f}s")


def main():
    parser = argparse.ArgumentParser(description="Receive raw Bayer frame from RPi and debayer")
    parser.add_argument("--port",      type=int,   default=9999,   help="TCP listen port")
    parser.add_argument("--width",     type=int,   default=6944,   help="Frame width px")
    parser.add_argument("--height",    type=int,   default=6944,   help="Frame height px")
    parser.add_argument("--out",       type=str,   default="frame.png", help="Output filename")
    parser.add_argument("--loop",      action="store_true",        help="Loop: keep waiting for frames")
    parser.add_argument("--timestamp", action="store_true",        help="Append timestamp to filenames")
    parser.add_argument("--save-raw",  action="store_true",        help="Also save raw .raw file")
    parser.add_argument("--r-gain",    type=float, default=2.278,  help="R AWB gain fallback (default=6500K)")
    parser.add_argument("--b-gain",    type=float, default=1.319,  help="B AWB gain fallback (default=6500K)")
    args = parser.parse_args()

    expected = args.width * args.height * 10 // 8
    out_path = Path(args.out)

    print(f"[*] Mode: {'loop' if args.loop else 'single'} | "
          f"{args.width}x{args.height} | "
          f"awaiting JPEG or packed 10-bit")

    frame_num = 0
    try:
        while True:
            frame_num += 1
            if args.loop and frame_num > 1:
                print(f"\n--- Frame #{frame_num} ---")

            raw, transfer_time, meta = receive_raw(args.port, expected)
            if raw:
                process_frame(raw, args.width, args.height, out_path,
                              transfer_time, frame_num,
                              args.timestamp, args.save_raw,
                              meta, args.r_gain, args.b_gain)

            if not args.loop:
                break

    except KeyboardInterrupt:
        print("\n[*] Exiting cleanly.")
        sys.exit(0)


if __name__ == "__main__":
    main()
