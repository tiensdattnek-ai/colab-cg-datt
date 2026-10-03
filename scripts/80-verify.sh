#!/usr/bin/env bash
# Tu kiem tra toan bo chuoi dich vu, tra ve ma loi neu co thanh phan hong
source "$(dirname "$0")/00-common.sh"
FAILED=0
t(){ printf '  %-26s' "$1"; if eval "$2" >/dev/null 2>&1; then echo "PASS"; else echo "FAIL"; FAILED=$((FAILED+1)); fi; }
echo "──── KIEM TRA HE THONG ────"
t "X server (:0)"        '[ -S /tmp/.X11-unix/X0 ]'
t "Do phan giai"         'DISPLAY=:0 xdpyinfo | grep -q dimensions'
t "XFCE / WM"            'pgrep -f "xfce4-session|xfwm4"'
t "PulseAudio"           'pgrep -x pulseaudio'
t "Audio sink ccg"       'sudo -u '"$CCG_USER"' pactl list short sinks | grep -q ccg'
t "Sunshine binary"      'command -v sunshine'
t "Sunshine port 47989"  'ss -ltn | grep -q :47989 || ss -lun | grep -q :47989'
t "Sunshine Web 47990"   'curl -sk --max-time 5 https://localhost:47990 -o /dev/null'
t "Moonlight Web"        'curl -s --max-time 5 http://localhost:'"$WEB_PORT"' -o /dev/null'
t "Tunnel process"       '[ "'"$TUNNEL"'" = none ] || pgrep -f "cloudflared|tailscaled"'
t "BBR enabled"          'sysctl -n net.ipv4.tcp_congestion_control | grep -q bbr'
echo "───────────────────────────"
[ "$FAILED" -eq 0 ] && ok "Tat ca OK" || warn "$FAILED muc loi — chay: sudo bash scripts/doctor.sh"
exit 0
