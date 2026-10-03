#!/usr/bin/env bash
# =====================================================================
#  Sunshine host — cai dat chong loi (deb -> AppImage -> flatpak)
#  + profile low-latency sinh theo encoder thuc te
# =====================================================================
source "$(dirname "$0")/00-common.sh"
[ -f "$CCG_HOME/encoder.env" ] && source "$CCG_HOME/encoder.env"
SUN_API="https://api.github.com/repos/LizardByte/Sunshine/releases/latest"

# --------------------------------------------------------------- resolver
resolve_sunshine_url() {
  local arch arch2 id ver code json url
  case "$(uname -m)" in aarch64|arm64) arch=arm64; arch2=aarch64 ;; *) arch=amd64; arch2=x86_64 ;; esac
  . /etc/os-release; id=$ID; ver=$VERSION_ID; code=${VERSION_CODENAME:-}
  json=$(curl -sL --retry 3 --max-time 30 "$SUN_API" | grep -oE 'https://[^"]+\.(deb|AppImage)')
  [ -z "$json" ] && { echo ""; return; }
  case "$id" in
    ubuntu|pop|linuxmint|neon|zorin|elementary)
      # URL bi encode: '+' -> '%2B', nen KHONG match dau '+'
      url=$(echo "$json" | grep -E "ubuntu${ver}_${arch}\.deb$" | head -1)
      # khong co ban dung version -> lay ban ubuntu moi nhat <= version hien tai
      [ -z "$url" ] && url=$(echo "$json" | grep -E "ubuntu[0-9.]+_${arch}\.deb$" \
          | sed -E "s|.*ubuntu([0-9.]+)_${arch}\.deb$|\1 &|" \
          | awk -v v="$ver" '$1+0<=v+0' | sort -rn | head -1 | cut -d' ' -f2-) ;;
    debian|raspbian|kali)
      url=$(echo "$json" | grep -E "debian${code}_${arch}\.deb$" | head -1) ;;
  esac
  # fallback cuoi: AppImage (tu chua thu vien, chay moi distro)
  [ -z "$url" ] && url=$(echo "$json" | grep -E "_${arch2}\.AppImage$" | head -1)
  echo "$url"
}

install_from_deb() {
  local url="$1"
  say "Tai .deb: $(basename "${url//%2B/+}")"
  curl -fsSL --retry 3 -o /tmp/sunshine.deb "$url" || return 1
  dpkg -I /tmp/sunshine.deb >/dev/null 2>&1 || { warn "File .deb hong"; return 1; }
  apt-get install -y -qq /tmp/sunshine.deb >>"$CCG_LOG/apt.log" 2>&1 || {
    warn "Thieu phu thuoc -> dang vá bang apt --fix-broken"
    apt-get -y -qq --fix-broken install >>"$CCG_LOG/apt.log" 2>&1
    dpkg -i /tmp/sunshine.deb >>"$CCG_LOG/apt.log" 2>&1
    apt-get -y -qq --fix-broken install >>"$CCG_LOG/apt.log" 2>&1
  }
  command -v sunshine >/dev/null 2>&1
}

install_from_appimage() {
  local arch2 url
  case "$(uname -m)" in aarch64|arm64) arch2=aarch64 ;; *) arch2=x86_64 ;; esac
  url=$(curl -sL --retry 3 "$SUN_API" | grep -oE "https://[^\"]+_${arch2}\.AppImage" | head -1)
  [ -z "$url" ] && return 1
  say "Dung AppImage (khong phu thuoc goi he thong)"
  apt_q libfuse2 fuse3 2>/dev/null || true
  mkdir -p "$CCG_HOME/appimage"; cd "$CCG_HOME/appimage"
  curl -fsSL --retry 3 -o sunshine.AppImage "$url" || return 1
  chmod +x sunshine.AppImage
  # Colab/container thuong khong co FUSE -> giai nen thu cong
  ./sunshine.AppImage --appimage-extract >/dev/null 2>&1 || true
  if [ -x "$CCG_HOME/appimage/squashfs-root/AppRun" ]; then
    cat >/usr/local/bin/sunshine <<'WRAP'
#!/usr/bin/env bash
export APPDIR=/opt/ccg/appimage/squashfs-root
export LD_LIBRARY_PATH="$APPDIR/usr/lib:${LD_LIBRARY_PATH:-}"
exec "$APPDIR/usr/bin/sunshine" "$@"
WRAP
    [ -x "$CCG_HOME/appimage/squashfs-root/usr/bin/sunshine" ] || \
      sed -i 's|exec "$APPDIR/usr/bin/sunshine"|exec "$APPDIR/AppRun"|' /usr/local/bin/sunshine
  else
    printf '#!/usr/bin/env bash\nexec %s/appimage/sunshine.AppImage "$@"\n' "$CCG_HOME" >/usr/local/bin/sunshine
  fi
  chmod +x /usr/local/bin/sunshine
  cd - >/dev/null
  sunshine --version >/dev/null 2>&1 || command -v sunshine >/dev/null
}

install_from_flatpak() {
  say "Thu Flatpak"
  apt_q flatpak || return 1
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1
  flatpak install -y --noninteractive flathub dev.lizardbyte.app.Sunshine >>"$CCG_LOG/apt.log" 2>&1 || return 1
  printf '#!/usr/bin/env bash\nexec flatpak run dev.lizardbyte.app.Sunshine "$@"\n' >/usr/local/bin/sunshine
  chmod +x /usr/local/bin/sunshine
}

# --------------------------------------------------------------- cai dat
if command -v sunshine >/dev/null 2>&1; then
  ok "Sunshine da co san: $(sunshine --version 2>/dev/null | head -1)"
else
  say "Cai Sunshine (host streaming)"
  # Mot so image Colab tat kho 'universe' -> thieu libqt6 -> cai .deb that bai
  if command -v add-apt-repository >/dev/null 2>&1; then
    add-apt-repository -y universe >>"$CCG_LOG/apt.log" 2>&1 || true
    apt-get update -qq >>"$CCG_LOG/apt.log" 2>&1 || true
  fi
  apt_q libminiupnpc17 libminiupnpc18 libevdev2 libnotify4 libcurl4 libdrm2 libnuma1 \
        libpulse0 libopus0 libva2 libva-drm2 libvdpau1 libxtst6 libvulkan1 \
        libqt6core6 libqt6gui6 libqt6widgets6 libqt6svg6 2>/dev/null || true
  URL=$(resolve_sunshine_url)
  INSTALLED=0
  if [ -n "$URL" ] && [[ "$URL" == *.deb ]]; then
    install_from_deb "$URL" && INSTALLED=1 || warn "Cai .deb that bai, chuyen sang AppImage"
  fi
  [ "$INSTALLED" = 0 ] && { install_from_appimage && INSTALLED=1 || warn "AppImage that bai"; }
  [ "$INSTALLED" = 0 ] && { install_from_flatpak && INSTALLED=1 || true; }
  if [ "$INSTALLED" = 0 ]; then
    echo "----- 30 dong cuoi apt.log -----"; tail -30 "$CCG_LOG/apt.log" 2>/dev/null
    die "Khong cai duoc Sunshine. Gui log tren vao issue cua repo."
  fi
fi
# --- Kiem chung binary thuc su chay duoc (thieu .so la doi sang AppImage) ---
if ! sunshine --version >/tmp/sunver.txt 2>&1; then
  if grep -qi "error while loading shared libraries\|not found" /tmp/sunver.txt; then
    warn "Binary thieu thu vien: $(head -1 /tmp/sunver.txt)"
    warn "-> chuyen sang AppImage"
    apt-get remove -y -qq sunshine >>"$CCG_LOG/apt.log" 2>&1 || true
    hash -r
    install_from_appimage || die "AppImage cung that bai, xem $CCG_LOG/apt.log"
  fi
fi
SUN_BIN=$(command -v sunshine)
setcap cap_sys_admin+p "$(readlink -f "$SUN_BIN")" 2>/dev/null || true
ok "Sunshine: $SUN_BIN"

# --------------------------------------------------------------- cau hinh
CFG="/home/$CCG_USER/.config/sunshine"
install -d -o "$CCG_USER" -g "$CCG_USER" "$CFG"
QP=${QP:-24}; FEC=${FEC:-10}; ENCODER=${ENCODER:-software}; CODEC=${CODEC:-h264}

case "$CODEC" in
  hevc) CODECLINE="hevc_mode = 2" ;;
  av1)  CODECLINE="av1_mode = 2"  ;;
  *)    CODECLINE="hevc_mode = 1" ;;
esac
# Chi ghi tham so rieng cua tung encoder -> tranh canh bao "unrecognized option"
EXTRA=""
case "$ENCODER" in
  nvenc) EXTRA=$'nvenc_preset = 1\nnvenc_twopass = disabled\nnvenc_spatial_aq = disabled\nnvenc_vbv_increase = 20\nnvenc_realtime_hags = enabled\nnvenc_latency_over_power = enabled' ;;
  vaapi) EXTRA=$'vaapi_strict_rc_buffer = enabled' ;;
  software) EXTRA=$'sw_preset = superfast\nsw_tune = zerolatency' ;;
esac

sed -e "s|__NAME__|Colab-CG-DATT|" -e "s|__ENCODER__|$ENCODER|" \
    -e "s|__QP__|$QP|" -e "s|__FEC__|$FEC|" -e "s|__CODECLINE__|$CODECLINE|" \
    "$(dirname "$0")/../config/sunshine.conf.tmpl" >"$CFG/sunshine.conf"
printf '\n%s\n' "$EXTRA" >>"$CFG/sunshine.conf"
cp "$(dirname "$0")/../config/apps.json" "$CFG/apps.json"
chown -R "$CCG_USER:$CCG_USER" "$CFG"

# --------------------------------------------------------------- chuan bi runtime
modprobe uinput 2>/dev/null || true
[ -e /dev/uinput ] && chmod 0666 /dev/uinput 2>/dev/null || \
  warn "Khong co /dev/uinput (binh thuong tren Colab) — chuot/phim van chay qua X11, gamepad ao se tat"

UIDG=$(id -u "$CCG_USER")
install -d -m 0700 -o "$CCG_USER" -g "$CCG_USER" "/run/user/$UIDG"
export DISPLAY=:0; xhost +local: >/dev/null 2>&1 || true

# Dat credential bang CLI (khong phu thuoc web API)
as_user sunshine --creds admin admin >>"$CCG_LOG/sunshine.log" 2>&1 || true

# --------------------------------------------------------------- chay
start_sunshine() { # start_sunshine <mode>
  pkill -f '[s]unshine' 2>/dev/null || true; sleep 1
  if [ "$1" = root ]; then
    DISPLAY=:0 HOME="/home/$CCG_USER" XDG_RUNTIME_DIR="/run/user/$UIDG" \
      nohup sunshine "$CFG/sunshine.conf" >>"$CCG_LOG/sunshine.log" 2>&1 &
  else
    as_user sunshine "$CFG/sunshine.conf" >>"$CCG_LOG/sunshine.log" 2>&1 &
  fi
}

: >"$CCG_LOG/sunshine.log"
start_sunshine user
if ! wait_port 47990 60; then
  warn "Chua mo cong 47990 bang user '$CCG_USER' — thu lai bang root"
  tail -15 "$CCG_LOG/sunshine.log"
  start_sunshine root
  if ! wait_port 47990 50; then
    warn "Van that bai — thu che do software encoder (loai tru loi NVENC)"
    sed -i 's/^encoder = .*/encoder = software/' "$CFG/sunshine.conf"
    sed -i '/^nvenc_/d' "$CFG/sunshine.conf"
    start_sunshine root
    if ! wait_port 47990 50; then
      echo; echo "════════ NHAT KY SUNSHINE (40 dong cuoi) ════════"
      tail -40 "$CCG_LOG/sunshine.log"
      echo "═════════════════════════════════════════════════"
      echo "Goi y: X dang chay? -> ls /tmp/.X11-unix ; DISPLAY=:0 xdpyinfo | head -3"
      die "Sunshine khong khoi dong duoc (xem nhat ky tren)"
    fi
    ENCODER=software; warn "Da ha ve software encoder de chay duoc"
  fi
fi

for _ in 1 2 3; do
  curl -s -k --max-time 5 -X POST https://localhost:47990/api/password \
    -H 'Content-Type: application/json' \
    -d '{"currentUsername":"","currentPassword":"","newUsername":"admin","newPassword":"admin","confirmNewPassword":"admin"}' >/dev/null 2>&1 && break
  sleep 2
done
mark SUNSHINE "$ENCODER"
grep -iE "error|fatal|fail" "$CCG_LOG/sunshine.log" | head -5 | sed 's/^/  log: /' || true
ok "Sunshine chay • encoder=$ENCODER • codec=$CODEC • UI https://localhost:47990 (admin/admin)"
