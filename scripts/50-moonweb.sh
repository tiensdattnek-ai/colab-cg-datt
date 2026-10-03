#!/usr/bin/env bash
# Moonlight Web client (choi ngay tren trinh duyet, khong cai app)
source "$(dirname "$0")/00-common.sh"
say "Cai Moonlight Web client"
BIN=/usr/local/bin/colab-moonweb
curl -sLk -o "$BIN" https://raw.githubusercontent.com/kmille36/Colab-Cloud-Gaming/main/colab-moonweb
chmod +x "$BIN"
pkill -f colab-moonweb 2>/dev/null || true; sleep 1
WEB_PORT="$WEB_PORT" HOST=127.0.0.1 nohup "$BIN" >"$CCG_LOG/moonweb.log" 2>&1 &
wait_port "$WEB_PORT" 30 || warn "Moonlight Web chua len cong $WEB_PORT (xem $CCG_LOG/moonweb.log)"
ok "Moonlight Web tren cong $WEB_PORT"
