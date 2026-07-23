# User Manual — Pi Camera Module 3 Wide (IMX708) Streaming Setup

**Target OS:** Raspberry Pi OS Lite **64-bit**
**Hardware:** Raspberry Pi + Camera Module 3 Wide (Sony IMX708 sensor)
**Purpose:** Stream live video from the camera over the network

---

## 1. Flash the SD Card

Flash **Raspberry Pi OS Lite 64-bit** to the SD card using Raspberry Pi Imager (or equivalent).

During imaging, set the following credentials:

| Setting | Value |
|---|---|
| Hostname | `retscreen` |
| Username | `retscreen` |
| Password | `retinopathy` |

> Enable SSH in the Imager's advanced settings so you can connect headlessly once the Pi boots.

---

## 2. Configure the Camera Overlay

Boot the Pi and edit the boot config file:

```bash
sudo nano /boot/firmware/config.txt
```

Add/set the following:

```ini
camera_auto_detect=0
dtoverlay=imx708
```

- `camera_auto_detect=0` — disables automatic camera detection so the explicit overlay is used instead
- `dtoverlay=imx708` — loads the correct driver overlay for the Camera Module 3 sensor

Save and exit, then reboot for the changes to take effect:

```bash
sudo reboot
```

---

## 3. Install Required Packages

Once rebooted, install the camera and imaging libraries:

```bash
sudo apt update
sudo apt install -y python3-picamera2 python3-pil
```

---

## 4. Connect to the Pi

Find the Pi's IP address on your network. In this setup, the Pi was assigned:

```
192.168.2.9
```

Connect over SSH:

```bash
ssh retscreen@192.168.2.9
```

(password: `retinopathy`)

---

## 5. Deploy the Streaming Script

From your computer, copy the streaming script to the Pi's home directory:

```bash
scp /path/to/stream_imx708.py retscreen@192.168.2.9:~/
```

---

## 6. Start the Stream

On the Pi, run the script:

```bash
python3 ~/stream_imx708.py
```

This starts the video stream from the Camera Module 3 Wide.

---

## Quick Reference

| Item | Value |
|---|---|
| Hostname | `retscreen` |
| Username | `retscreen` |
| Password | `retinopathy` |
| Camera overlay | `dtoverlay=imx708` |
| Pi IP address | `192.168.2.9` |
| Streaming script | `stream_imx708.py` (run from home directory) |

---

## Troubleshooting

- **Camera not detected:** confirm `camera_auto_detect=0` and `dtoverlay=imx708` are both present in `/boot/firmware/config.txt`, then reboot.
- **SSH connection refused:** verify SSH was enabled during imaging, and that the Pi's IP address hasn't changed (check your router's DHCP client list if `192.168.2.9` no longer responds).
- **Script fails to run:** confirm `python3-picamera2` and `python3-pil` installed successfully with `apt list --installed | grep picamera2`.
