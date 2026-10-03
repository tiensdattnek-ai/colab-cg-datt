#!/usr/bin/env bash
# Expose ra Internet. cloudflare = tien nhat; tailscale = do tre thap nhat (UDP truc tiep)
source "$(dirname "$0")/00-common.sh"

case "$TUNNEL" in
tailscale)
  say "Thiet lap Tailscale (UDP truc tiep — do tre thap nhat)"
  command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh >>"$CCG_LOG/apt.log" 2>&1
  tailscaled --tun=userspace-networking --socks5-server=localhost:1055 >"$CCG_LOG/tailscaled.log" 2>&1 &
  sleep 3
  if [ -n "${TS_AUTHKEY:-}" ]; then tailscale up --authkey="$TS_AUTHKEY" --hostname=colab-cg --accept-dns=false
  else tailscale up --hostname=colab-cg --accept-dns=false 2>&1 | tee "$CCG_LOG/ts-login.txt"; fi
  TS_IP=$(tailscale ip -4 2>/dev/null | head -1)
  { echo "MODE=tailscale"; echo "WEB_URL=http://${TS_IP}:${WEB_PORT}"; echo "SUN_URL=https://${TS_IP}:47990"; echo "HOST_ADDR=${TS_IP}"; } >"$CCG_HOME/urls.env"
  ;;
none)
  { echo "MODE=none"; echo "WEB_URL=http://127.0.0.1:${WEB_PORT}"; echo "SUN_URL=https://127.0.0.1:47990"; echo "HOST_ADDR=127.0.0.1"; } >"$CCG_HOME/urls.env"
  ;;
*)
  say "Mo Cloudflare Tunnel (QUIC — thap tre hon HTTP/2)"
  if ! command -v cloudflared >/dev/null 2>&1; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cf.deb
    apt-get install -y -qq /tmp/cf.deb >>"$CCG_LOG/apt.log" 2>&1
  fi
  pkill -f cloudflared 2>/dev/null || true; sleep 1
  CFA="--no-autoupdate --protocol quic --edge-ip-version auto --loglevel warn"
  cloudflared tunnel $CFA --url "http://localhost:${WEB_PORT}" >"$CCG_LOG/cf-web.log" 2>&1 &
  cloudflared tunnel $CFA --url "https://localhost:47990" --no-tls-verify >"$CCG_LOG/cf-sun.log" 2>&1 &
  for _ in $(seq 1 40); do
    WEB_URL=$(grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' "$CCG_LOG/cf-web.log" | head -1)
    SUN_URL=$(grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' "$CCG_LOG/cf-sun.log" | head -1)
    [ -n "${WEB_URL:-}" ] && [ -n "${SUN_URL:-}" ] && break; sleep 2
  done
  { echo "MODE=cloudflare"; echo "WEB_URL=${WEB_URL:-}"; echo "SUN_URL=${SUN_URL:-}"; echo "HOST_ADDR=localhost"; } >"$CCG_HOME/urls.env"
  ;;
esac
ok "Tunnel: $TUNNEL"
