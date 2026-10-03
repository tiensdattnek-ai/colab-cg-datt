#!/usr/bin/env bash
# =====================================================================
#  Colab-CG-DATT :: one-shot installer
#  Usage:  sudo RES_W=1920 RES_H=1080 FPS=60 TUNNEL=cloudflare bash scripts/install.sh
# =====================================================================
set -u
D="$(cd "$(dirname "$0")" && pwd)"
source "$D/00-common.sh"
START=$(date +%s)
[ "$(id -u)" -eq 0 ] || die "Can chay bang sudo/root"

cat <<'BAN'
  ____      _       _         ____ ____    ____    _  _____ _____
 / ___|___ | | __ _| |__     / ___/ ___|  |  _ \  / \|_   _|_   _|
| |   / _ \| |/ _` | '_ \   | |  | |  _   | | | |/ _ \ | |   | |
| |__| (_) | | (_| | |_) |  | |__| |_| |  | |_| / ___ \| |   | |
 \____\___/|_|\__,_|_.__/    \____\____|  |____/_/   \_\_|   |_|
        Linux XFCE cloud gaming  •  Sunshine + Moonlight Web
BAN
echo "   Target: ${RES_W}x${RES_H}@${FPS}  |  tunnel=${TUNNEL}  |  lowlat=${LOWLAT}"
echo

run_step() { # run_step <file> <ten> <critical:0|1>
  local f="$1" n="$2" crit="${3:-0}"
  if bash "$D/$f"; then return 0; fi
  warn "Buoc '$n' loi -> thu lai lan 2"
  if bash "$D/$f"; then ok "'$n' thanh cong o lan 2"; return 0; fi
  if [ "$crit" = 1 ]; then
    echo; echo "=== 25 dong cuoi log lien quan ==="
    tail -25 "$CCG_LOG"/*.log 2>/dev/null | tail -40
    die "Buoc bat buoc '$n' that bai. Chay: sudo bash scripts/doctor.sh"
  fi
  warn "Bo qua '$n' (khong bat buoc)"; return 0
}

: > "$CCG_HOME/state.env"
run_step 10-desktop.sh  "Desktop XFCE"   1
run_step 20-audio.sh    "Audio"          0
run_step 30-gpu.sh      "Phat hien GPU"  0
run_step 40-sunshine.sh "Sunshine"       1
run_step 50-moonweb.sh  "Moonlight Web"  0
run_step 70-latency.sh  "Tuning do tre"  0
run_step 60-tunnel.sh   "Tunnel"         0
echo; bash "$D/80-verify.sh"

source "$CCG_HOME/urls.env" 2>/dev/null || true
source "$CCG_HOME/encoder.env" 2>/dev/null || true
cp -f "$D/pair.sh" "$D/status.sh" "$D/backup.sh" "$D/doctor.sh" /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/pair.sh /usr/local/bin/status.sh /usr/local/bin/backup.sh /usr/local/bin/doctor.sh 2>/dev/null || true

ELAPSED=$(( $(date +%s) - START ))
cat <<BANNER

╔══════════════════════════════════════════════════════════════╗
║   MAY AO CLOUD GAMING SAN SANG  (${ELAPSED}s)
╠══════════════════════════════════════════════════════════════╣
║  🎮 Choi game (web) : ${WEB_URL:-<xem log cf-web.log>}
║  ⚙️  Sunshine UI     : ${SUN_URL:-<xem log cf-sun.log>}
║  👤 Dang nhap       : admin / admin
║  🖥  Che do          : ${RES_W}x${RES_H}@${FPS} • ${ENCODER:-?} • ${CODEC:-?}
╠══════════════════════════════════════════════════════════════╣
║  B1. Mo link choi game, them host: ${HOST_ADDR:-localhost}
║  B2. Lay PIN 4 so, chay:  !sudo bash scripts/pair.sh <PIN>
║  B3. Chon app "Desktop" -> vao XFCE
║  ❓ Loi gi?  sudo bash scripts/doctor.sh  (tu chan doan + sua)
╚══════════════════════════════════════════════════════════════╝
BANNER
