#!/usr/bin/env bash
# Bang dieu khien: trang thai dich vu + do tre + link
source "$(dirname "$0")/00-common.sh" 2>/dev/null || CCG_HOME=/opt/ccg CCG_LOG=/var/log/ccg
source "$CCG_HOME/urls.env" 2>/dev/null || true
source "$CCG_HOME/encoder.env" 2>/dev/null || true
chk(){ pgrep -x "$1" >/dev/null && echo "  ● $2 : RUNNING" || echo "  ○ $2 : STOPPED"; }
echo "──────── DICH VU ────────"
chk Xorg "X server"; chk xfce4-session "XFCE"; chk pulseaudio "Audio"
chk sunshine "Sunshine"; chk colab-moonweb "Moonlight Web"; chk cloudflared "Tunnel"
echo "──────── LINK ───────────"
echo "  Game : ${WEB_URL:-n/a}"
echo "  UI   : ${SUN_URL:-n/a}"
echo "──────── PHAN CUNG ──────"
echo "  Encoder: ${ENCODER:-?} / ${CODEC:-?}"
command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,clocks.sm --format=csv,noheader | sed 's/^/  GPU: /'
echo "  CPU load:$(cut -d' ' -f1-3 /proc/loadavg)  RAM:$(free -m | awk '/Mem:/{print $3"/"$2" MB"}')"
echo "──────── MANG ───────────"
echo "  qdisc/cc: $(sysctl -n net.core.default_qdisc 2>/dev/null)/$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
ping -c3 -q 1.1.1.1 2>/dev/null | tail -1 | sed 's/^/  RTT edge: /'
echo "──────── FRAME (Sunshine) ───"
grep -iE "encode|latency|fps" "$CCG_LOG/sunshine.log" 2>/dev/null | tail -5 | sed 's/^/  /'
