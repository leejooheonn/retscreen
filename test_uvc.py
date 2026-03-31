"""
test_uvc.py — Windows-side UVC camera diagnostic tool.
Lists all cameras, then tries to open each one with OpenCV/DirectShow and
measures frame delivery. Run with: python test_uvc.py
"""
import sys
import time
import cv2

try:
    from PySide6.QtMultimedia import QMediaDevices
    from PySide6.QtWidgets import QApplication
    _qt_app = QApplication.instance() or QApplication(sys.argv)
    print("=== Qt camera list ===")
    cameras = QMediaDevices.videoInputs()
    if not cameras:
        print("  (none found via Qt)")
    for i, cam in enumerate(cameras):
        print(f"  [{i}] {cam.description()}")
except Exception as e:
    print(f"Qt not available: {e}")

print("\n=== OpenCV DirectShow probe ===")
found = []
for idx in range(10):
    cap = cv2.VideoCapture(idx, cv2.CAP_DSHOW)
    if cap.isOpened():
        w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        print(f"  Camera {idx}: {w}x{h} — testing frame capture for 5s...")
        cap.release()
        found.append(idx)

if not found:
    print("  No cameras found via OpenCV/DirectShow")
    sys.exit(1)

for idx in found:
    cap = cv2.VideoCapture(idx, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print(f"  Camera {idx}: failed to open")
        continue
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"\nCamera {idx} @ {w}x{h} — press Q to skip to next camera")

    t0 = time.time()
    frames = 0
    errors = 0
    while time.time() - t0 < 10:
        ret, frame = cap.read()
        if ret:
            frames += 1
            elapsed = time.time() - t0
            fps = frames / elapsed if elapsed > 0 else 0
            cv2.putText(frame, f"Cam {idx}  frame={frames}  {fps:.1f}fps",
                        (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.imshow(f"UVC Test — Camera {idx}", frame)
        else:
            errors += 1
            if errors > 30:
                print(f"  Too many read errors ({errors}), stopping")
                break
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:
            break

    elapsed = time.time() - t0
    fps = frames / elapsed if elapsed > 0 else 0
    print(f"  Result: {frames} frames in {elapsed:.1f}s = {fps:.1f} fps, {errors} errors")
    cap.release()
    cv2.destroyAllWindows()
