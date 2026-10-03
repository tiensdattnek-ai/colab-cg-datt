#!/usr/bin/env bash
# Sunshine host + profile do tre thap + danh sach app
source "$(dirname "$0")/00-common.sh"
[ -f "$CCG_HOME/encoder.env" ] && source "$CCG_HOME/encoder.env"

say "Cai Sunshine (host streaming)"
if ! command -v sunshine >/dev/null 2>&1; then
  UB=$(. /etc/os-release; echo "$VERSION_ID")
  API=https://api.github.com/repos/LizardByte/Sunshine/releases/latest
  URL=$(curl -sL $API | jq -r '.assets[].browser_download_url' | grep -iE "ubuntu-${UB}.*amd64\.deb$" | head -1)
  [ -z "$URL" ] && URL=$(curl -sL $API | jq -r '.assets[].browser_download_url' | grep -iE "ubuntu.*amd64\.deb$" | sort -V | tail -1)
  [ -z "$URL" ] && die "Khong tim thay ban Sunshine phu hop"
  wget -q "$URL" -O /tmp/sunshine.deb
  apt-get install -y -qq /tmp/sunshine.deb >>"$CCG_LOG/apt.log" 2>&1 || die "Cai Sunshine that bai"
fi
setcap cap_sys_admin+p "$(readlink -f "$(command -v sunshine)")" 2>/dev/null || true

CFG="/home/$CCG_USER/.config/sunshine"
install -d -o "$CCG_USER" -g "$CCG_USER" "$CFG"

QP=${QP:-24}; FEC=${FEC:-10}
CODECLINE=""
case "$CODEC" in
  hevc) CODECLINE="hevc_mode = 2" ;;
  av1)  CODECLINE="av1_mode = 2"  ;;
  *)    CODECLINE="hevc_mode = 1" ;;
esac
sed -e "s|__NAME__|Colab-CG-DATT|" -e "s|__ENCODER__|${ENCODER:-software}|" \
    -e "s|__QP__|$QP|" -e "s|__FEC__|$FEC|" -e "s|__CODECLINE__|$CODECLINE|" \
    "$(dirname "$0")/../config/sunshine.conf.tmpl" >"$CFG/sunshine.conf"
cp "$(dirname "$0")/../config/apps.json" "$CFG/apps.json"
chown -R "$CCG_USER:$CCG_USER" "$CFG"

pkill -f 'sunshine' 2>/dev/null || true; sleep 1
as_user sunshine "$CFG/sunshine.conf" >"$CCG_LOG/sunshine.log" 2>&1 &
wait_port 47990 45 || warn "Sunshine chua mo 47990, xem $CCG_LOG/sunshine.log"

# Khoi tao credential web UI
curl -s -k -X POST https://localhost:47990/api/password \
  -H 'Content-Type: application/json' \
  -d '{"currentUsername":"","currentPassword":"","newUsername":"admin","newPassword":"admin","confirmNewPassword":"admin"}' >/dev/null 2>&1
ok "Sunshine chay (admin/admin) — encoder=${ENCODER:-software} codec=${CODEC:-h264}"
