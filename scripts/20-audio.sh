#!/usr/bin/env bash
# PulseAudio low-latency: tat timer scheduling, fragment 5ms
source "$(dirname "$0")/00-common.sh"
say "Cau hinh audio do tre thap"
apt_q pulseaudio pulseaudio-utils

UID_G=$(id -u "$CCG_USER")
install -d -o "$CCG_USER" -g "$CCG_USER" "/home/$CCG_USER/.config/pulse"
cat >"/home/$CCG_USER/.config/pulse/daemon.conf" <<'PCONF'
default-sample-rate = 48000
alternate-sample-rate = 48000
default-sample-channels = 2
default-fragments = 2
default-fragment-size-msec = 5
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 9
resample-method = speex-float-1
flat-volumes = no
exit-idle-time = -1
PCONF
chown -R "$CCG_USER:$CCG_USER" "/home/$CCG_USER/.config/pulse"

as_user pulseaudio -k >/dev/null 2>&1 || true; sleep 1
as_user pulseaudio --start --exit-idle-time=-1 >"$CCG_LOG/pulse.log" 2>&1
sleep 2
as_user pactl load-module module-null-sink sink_name=ccg \
  sink_properties="device.description=CCG-Stream" \
  tsched=0 fragments=2 fragment_size_msec=5 rate=48000 channels=2 >/dev/null 2>&1 || true
as_user pactl set-default-sink ccg >/dev/null 2>&1 || true
ok "Audio sink 'ccg' @48kHz, buffer ~10ms"
