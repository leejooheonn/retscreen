#!/bin/bash
set -e

GADGET=/sys/kernel/config/usb_gadget/retinex
FUNCTION=uvc.0
UVC="${GADGET}/functions/${FUNCTION}"
ACM="${GADGET}/functions/acm.usb0"

# modprobe wrappers (modules may already be built-in or loaded)
load_mod() { /sbin/modprobe "$1" 2>/dev/null || true; }

echo "Loading kernel modules..."
load_mod libcomposite
load_mod usb_f_uvc
load_mod usb_f_acm

# ---- Tear down any previous gadget cleanly ----------------------
if [ -d "$GADGET" ]; then
    echo "Cleaning up previous gadget..."
    echo "" > "${GADGET}/UDC" 2>/dev/null || true
    sleep 0.2
    rm -f "${GADGET}/configs/c.1/${FUNCTION}"    2>/dev/null || true
    rm -f "${GADGET}/configs/c.1/acm.usb0"       2>/dev/null || true
    rm -f "${UVC}/streaming/class/ss/h"           2>/dev/null || true
    rm -f "${UVC}/streaming/class/hs/h"           2>/dev/null || true
    rm -f "${UVC}/streaming/class/fs/h"           2>/dev/null || true
    rm -f "${UVC}/streaming/header/h/u"           2>/dev/null || true
    rm -f "${UVC}/streaming/header/h/m"           2>/dev/null || true
    rmdir "${UVC}/streaming/class/ss"             2>/dev/null || true
    rmdir "${UVC}/streaming/class/hs"             2>/dev/null || true
    rmdir "${UVC}/streaming/class/fs"             2>/dev/null || true
    rmdir "${UVC}/streaming/header/h"             2>/dev/null || true
    rmdir "${UVC}/streaming/uncompressed/u/1080p" 2>/dev/null || true
    rmdir "${UVC}/streaming/uncompressed/u/720p"  2>/dev/null || true
    rmdir "${UVC}/streaming/uncompressed/u/480p"  2>/dev/null || true
    rmdir "${UVC}/streaming/uncompressed/u"       2>/dev/null || true
    rmdir "${UVC}/streaming/uncompressed"         2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/1080p"        2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/720p"         2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/480p"         2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/1920x1080"    2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/3264x2448"    2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m/1920x1080"    2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg/m"              2>/dev/null || true
    rmdir "${UVC}/streaming/mjpeg"                2>/dev/null || true
    rm -f "${UVC}/control/class/fs/h"             2>/dev/null || true
    rmdir "${UVC}/control/class/fs"               2>/dev/null || true
    rmdir "${UVC}/control/header/h"               2>/dev/null || true
    rmdir "${UVC}"                                2>/dev/null || true
    rmdir "$ACM"                                  2>/dev/null || true
    rmdir "${GADGET}/configs/c.1/strings/0x409"   2>/dev/null || true
    rmdir "${GADGET}/configs/c.1"                 2>/dev/null || true
    rmdir "${GADGET}/strings/0x409"               2>/dev/null || true
    rmdir "${GADGET}"                             2>/dev/null || true
fi

mkdir -p "$GADGET"
cd "$GADGET"

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB
echo 0xEF   > bDeviceClass
echo 0x02   > bDeviceSubClass
echo 0x01   > bDeviceProtocol

mkdir -p strings/0x409
echo "Retinex Ltd"  > strings/0x409/manufacturer
echo "Retinex Camera" > strings/0x409/product
echo "RETINEX00002"   > strings/0x409/serialnumber

# ---- UVC function (exactly per Raspberry Pi tutorial) -----------
create_frame() {
    local FUNC=$1 WIDTH=$2 HEIGHT=$3 FORMAT=$4 NAME=$5
    local wdir="functions/$FUNC/streaming/$FORMAT/$NAME/${HEIGHT}p"
    mkdir -p "$wdir"
    echo "$WIDTH"  > "$wdir/wWidth"
    echo "$HEIGHT" > "$wdir/wHeight"
    echo $(( WIDTH * HEIGHT * 2 )) > "$wdir/dwMaxVideoFrameBufferSize"
    cat <<EOF > "$wdir/dwFrameInterval"
$6
EOF
}

mkdir -p "functions/$FUNCTION"
echo "Retinex Camera" > "functions/$FUNCTION/function_name"

INTERVALS="333333
666666
1000000"

# MJPEG frames only (YUYV omitted — forces MJPEG negotiation, avoids stride artifacts)
create_frame "$FUNCTION" 640  480  mjpeg m "$INTERVALS"
create_frame "$FUNCTION" 1280 720  mjpeg m "$INTERVALS"
create_frame "$FUNCTION" 1920 1080 mjpeg m "$INTERVALS"

echo 2048 > "functions/$FUNCTION/streaming_maxpacket"

mkdir -p "functions/$FUNCTION/streaming/header/h"
ln -s "$(pwd)/functions/$FUNCTION/streaming/mjpeg/m" \
      "functions/$FUNCTION/streaming/header/h/m"
mkdir -p "functions/$FUNCTION/streaming/class/fs"
mkdir -p "functions/$FUNCTION/streaming/class/hs"
mkdir -p "functions/$FUNCTION/streaming/class/ss"
ln -s "$(pwd)/functions/$FUNCTION/streaming/header/h" \
      "functions/$FUNCTION/streaming/class/fs/h"
ln -s "$(pwd)/functions/$FUNCTION/streaming/header/h" \
      "functions/$FUNCTION/streaming/class/hs/h"
ln -s "$(pwd)/functions/$FUNCTION/streaming/header/h" \
      "functions/$FUNCTION/streaming/class/ss/h"

mkdir -p "functions/$FUNCTION/control/header/h"
mkdir -p "functions/$FUNCTION/control/class/fs"
ln -s "$(pwd)/functions/$FUNCTION/control/header/h" \
      "functions/$FUNCTION/control/class/fs/h"

# ---- CDC ACM function -------------------------------------------
mkdir -p "functions/acm.usb0"

# ---- USB configuration ------------------------------------------
mkdir -p configs/c.1/strings/0x409
echo "UVC"  > configs/c.1/strings/0x409/configuration
echo 500    > configs/c.1/MaxPower
ln -sf "$(pwd)/functions/$FUNCTION"   configs/c.1/${FUNCTION}
ln -sf "$(pwd)/functions/acm.usb0"    configs/c.1/acm.usb0

# ---- Activate ---------------------------------------------------
UDC=$(ls /sys/class/udc | head -1)
echo "$UDC" > UDC
echo "Gadget active: ${UDC}"
