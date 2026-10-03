#!/usr/bin/env bash
# Tu chan doan + tu sua cac loi pho bien, khong can cai lai tu dau
D="$(cd "$(dirname "$0")" && pwd)"; source "$D/00-common.sh"
[ "$(id -u)" -eq 0 ] || die "Can sudo"
say "Bac si CCG dang kham..."

fixed=0
if [ ! -S /tmp/.X11-unix/X0 ]; then warn "X chet -> khoi dong lai"; bash "$D/10-desktop.sh"; fixed=1; fi
if ! pgrep -x pulseaudio >/dev/null; then warn "Audio chet -> khoi dong lai"; bash "$D/20-audio.sh"; fixed=1; fi
if ! command -v sunshine >/dev/null || ! curl -sk --max-time 5 https://localhost:47990 -o /dev/null; then
  warn "Sunshine chet -> cai/chay lai"; bash "$D/40-sunshine.sh"; fixed=1; fi
if ! curl -s --max-time 5 "http://localhost:$WEB_PORT" -o /dev/null; then
  warn "Moonlight Web chet -> chay lai"; bash "$D/50-moonweb.sh"; fixed=1; fi
if [ "$TUNNEL" != none ] && ! pgrep -f "cloudflared|tailscaled" >/dev/null; then
  warn "Tunnel chet -> mo lai"; bash "$D/60-tunnel.sh"; fixed=1; fi
/usr/local/bin/ccg-prio 2>/dev/null || true

echo; bash "$D/80-verify.sh"
source "$CCG_HOME/urls.env" 2>/dev/null || true
echo; echo "  Link choi game: ${WEB_URL:-n/a}"
[ "$fixed" = 0 ] && ok "Khong phat hien su co" || ok "Da sua xong"
echo
echo "Log huu ich:"
for f in sunshine xorg moonweb cf-web apt; do
  [ -f "$CCG_LOG/$f.log" ] && echo "  • $CCG_LOG/$f.log ($(wc -l <"$CCG_LOG/$f.log") dong)"
done
