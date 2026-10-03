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

bash "$D/10-desktop.sh"  || die "desktop"
bash "$D/20-audio.sh"    || warn "audio co van de"
bash "$D/30-gpu.sh"      || warn "gpu detect"
bash "$D/40-sunshine.sh" || die "sunshine"
bash "$D/50-moonweb.sh"  || warn "moonlight-web"
bash "$D/70-latency.sh"  || warn "tuning"
bash "$D/60-tunnel.sh"   || warn "tunnel"

source "$CCG_HOME/urls.env" 2>/dev/null || true
source "$CCG_HOME/encoder.env" 2>/dev/null || true
cp -f "$D/pair.sh" "$D/status.sh" "$D/backup.sh" /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/pair.sh /usr/local/bin/status.sh /usr/local/bin/backup.sh 2>/dev/null || true

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
╚══════════════════════════════════════════════════════════════╝
BANNER
