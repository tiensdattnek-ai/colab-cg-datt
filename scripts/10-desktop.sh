#!/usr/bin/env bash
# XFCE desktop tren X server ao, toi uu cho streaming (tat compositing/animation)
source "$(dirname "$0")/00-common.sh"

say "Cai dat desktop XFCE + X server ao"
apt-get update -qq >>"$CCG_LOG/apt.log" 2>&1
apt_q xfce4 xfce4-terminal xfce4-taskmanager dbus-x11 xfconf \
      xserver-xorg-video-dummy xserver-xorg-core x11-xserver-utils x11-utils xdotool \
      mesa-utils libgl1-mesa-dri libglu1-mesa libvulkan1 \
      curl wget jq unzip socat procps sudo fonts-dejavu-core

if ! id "$CCG_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$CCG_USER"
  usermod -aG audio,video,input "$CCG_USER" 2>/dev/null || true
  echo "$CCG_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-$CCG_USER
  install -d -o "$CCG_USER" -g "$CCG_USER" "/run/user/$(id -u "$CCG_USER")"
fi
install -d -o "$CCG_USER" -g "$CCG_USER" "/run/user/$(id -u "$CCG_USER")"

# Modeline chinh xac theo RES/FPS -> tranh scaling (nguon tre an)
MODELINE=$(cvt "$RES_W" "$RES_H" "$FPS" 2>/dev/null | grep Modeline | cut -d' ' -f2-)
[ -z "$MODELINE" ] && MODELINE="\"1920x1080\" 148.50 1920 2448 2492 2640 1080 1084 1089 1125 +hsync +vsync"

cat >/etc/X11/xorg-ccg.conf <<XCONF
Section "ServerFlags"
  Option "AutoAddDevices" "false"
  Option "DontVTSwitch" "true"
  Option "BlankTime" "0"
  Option "StandbyTime" "0"
  Option "SuspendTime" "0"
  Option "OffTime" "0"
EndSection
Section "Monitor"
  Identifier "Monitor0"
  HorizSync 5.0-1000.0
  VertRefresh 5.0-300.0
  Modeline $MODELINE
  Option "PreferredMode" "${RES_W}x${RES_H}"
EndSection
Section "Device"
  Identifier "Card0"
  Driver "dummy"
  VideoRam 512000
EndSection
Section "Screen"
  Identifier "Screen0"
  Device "Card0"
  Monitor "Monitor0"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "${RES_W}x${RES_H}"
    Virtual $RES_W $RES_H
  EndSubSection
EndSection
XCONF

pkill -f "Xorg :0" 2>/dev/null || true
pkill -f "Xvfb :0" 2>/dev/null || true; sleep 1
rm -f /tmp/.X0-lock

# Container thuong khong co VT -> can -novtswitch -sharevts
Xorg :0 -config /etc/X11/xorg-ccg.conf -noreset -nolisten tcp \
     -novtswitch -sharevts vt1 >"$CCG_LOG/xorg.log" 2>&1 &
if ! wait_x 0 20; then
  warn "Xorg dummy that bai -> fallback Xvfb (van stream duoc)"
  tail -5 "$CCG_LOG/xorg.log" 2>/dev/null
  pkill -f "Xorg :0" 2>/dev/null || true; rm -f /tmp/.X0-lock
  apt_q xvfb
  Xvfb :0 -screen 0 "${RES_W}x${RES_H}x24" -nolisten tcp -dpi 96 +extension GLX +extension RANDR \
       >"$CCG_LOG/xorg.log" 2>&1 &
  wait_x 0 25 || die "Khong khoi dong duoc X server (xem $CCG_LOG/xorg.log)"
  mark XSERVER xvfb
else
  mark XSERVER xorg-dummy
fi
export DISPLAY=:0
xhost +local: >/dev/null 2>&1 || true

pkill -u "$CCG_USER" -f xfce4-session 2>/dev/null || true
as_user dbus-launch --exit-with-session startxfce4 >"$CCG_LOG/xfce.log" 2>&1 &
sleep 6

if [ "$LOWLAT" = "1" ]; then
  say "Tat compositing / hieu ung (giam 1-2 frame tre)"
  as_user xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
  as_user xfconf-query -c xfwm4 -p /general/sync_to_vblank -s false 2>/dev/null || true
  as_user xfconf-query -c xfwm4 -p /general/box_move -s true 2>/dev/null || true
  as_user xfconf-query -c xfwm4 -p /general/box_resize -s true 2>/dev/null || true
  as_user xfconf-query -c xsettings -p /Gtk/EnableAnimations -s false 2>/dev/null || true
  as_user xset s off -dpms 2>/dev/null || true
fi
# Kiem chung desktop that su len
if ! pgrep -u "$CCG_USER" -f xfce4-session >/dev/null; then
  warn "xfce4-session chua chay, thu lai bang xfwm4 toi gian"
  as_user dbus-launch xfwm4 >>"$CCG_LOG/xfce.log" 2>&1 &
  as_user xfdesktop >>"$CCG_LOG/xfce.log" 2>&1 &
  sleep 3
fi
mark DESKTOP ok
ok "Desktop ${RES_W}x${RES_H}@${FPS} san sang ($(DISPLAY=:0 xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}'))"
