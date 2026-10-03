#!/usr/bin/env bash
# Gom bao cao chan doan de dan vao issue / gui ho tro
source "$(dirname "$0")/00-common.sh" 2>/dev/null || { CCG_LOG=/var/log/ccg; CCG_HOME=/opt/ccg; }
OUT=/content/ccg-report.txt; [ -d /content ] || OUT=/tmp/ccg-report.txt
{
  echo "===== HE THONG ====="; . /etc/os-release; echo "$PRETTY_NAME | $(uname -r) | $(uname -m)"
  echo "nproc=$(nproc) ram=$(free -m|awk '/Mem:/{print $2}')MB"
  echo; echo "===== GPU ====="
  nvidia-smi 2>&1 | head -12
  echo "libnvidia-encode:"; ldconfig -p | grep -i nvidia-encode || echo "  (khong co trong ldcache)"
  find /usr -maxdepth 4 -name 'libnvidia-encode.so*' 2>/dev/null | sed 's/^/  /'
  echo; echo "===== STATE ====="; cat "$CCG_HOME/state.env" "$CCG_HOME/encoder.env" "$CCG_HOME/urls.env" 2>/dev/null
  echo; echo "===== TIEN TRINH ====="; pgrep -a -f 'Xorg|Xvfb|xfce|pulseaudio|sunshine|moonweb|cloudflared' | cut -c1-140
  echo; echo "===== CONG ====="; ss -ltnup 2>/dev/null | grep -E '47989|47990|8080|:0' | cut -c1-120
  for f in sunshine xorg xfce moonweb cf-web nvenc-test; do
    echo; echo "===== $f.log (40 dong cuoi) ====="; tail -40 "$CCG_LOG/$f.log" 2>/dev/null || echo "(khong co)"
  done
  echo; echo "===== apt.log (25 dong cuoi) ====="; tail -25 "$CCG_LOG/apt.log" 2>/dev/null
} > "$OUT" 2>&1
echo "Bao cao: $OUT ($(wc -l <"$OUT") dong)"
echo "--- 60 dong dau ---"; head -60 "$OUT"
