#!/usr/bin/env bash
# =====================================================================
#  Phat hien GPU + NVENC that su (khong tin moi mot nguon)
#  Colab mount driver NVIDIA ngoai ldcache -> phai tu tim & nap lai
# =====================================================================
source "$(dirname "$0")/00-common.sh"
say "Phat hien GPU / encoder phan cung"

DETECTED=software
NVENC_LIB=""

if has_nvidia; then
  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader | sed 's/^/     GPU: /'

  # --- B1: lam moi ldcache (Colab hay bi stale sau khi mount driver) ---
  ldconfig >/dev/null 2>&1 || true

  # --- B2: tim libnvidia-encode o MOI noi Colab/container hay dat ---
  for d in /usr/lib/x86_64-linux-gnu /usr/lib64-nvidia /usr/local/nvidia/lib64 \
           /usr/local/cuda/compat /usr/lib/wsl/lib /usr/lib /usr/lib64; do
    [ -d "$d" ] || continue
    f=$(ls "$d"/libnvidia-encode.so* 2>/dev/null | head -1) && [ -n "$f" ] && { NVENC_LIB="$f"; break; }
  done
  [ -z "$NVENC_LIB" ] && NVENC_LIB=$(ldconfig -p 2>/dev/null | awk '/libnvidia-encode\.so/{print $NF; exit}')
  [ -z "$NVENC_LIB" ] && NVENC_LIB=$(find /usr /opt -maxdepth 4 -name 'libnvidia-encode.so*' 2>/dev/null | head -1)

  # --- B3: neu thu vien nam ngoai ldcache -> nap vao ---
  if [ -n "$NVENC_LIB" ]; then
    LIBDIR=$(dirname "$NVENC_LIB")
    if ! ldconfig -p | grep -q libnvidia-encode; then
      echo "$LIBDIR" >/etc/ld.so.conf.d/zz-ccg-nvidia.conf
      ldconfig >/dev/null 2>&1 || true
      say "Da nap $LIBDIR vao ldconfig"
    fi
    # Sunshine can ten chuan libnvidia-encode.so.1
    [ -e "$LIBDIR/libnvidia-encode.so.1" ] || ln -sf "$NVENC_LIB" "$LIBDIR/libnvidia-encode.so.1" 2>/dev/null || true
    export LD_LIBRARY_PATH="$LIBDIR:${LD_LIBRARY_PATH:-}"
    echo "LD_LIBRARY_PATH=$LIBDIR" >>"$CCG_HOME/encoder.env"
    DETECTED=nvenc
  fi

  # --- B4: kiem chung bang ffmpeg (nguon su that cuoi cung) ---
  command -v ffmpeg >/dev/null 2>&1 || apt_q ffmpeg
  if command -v ffmpeg >/dev/null 2>&1; then
    if ffmpeg -hide_banner -loglevel error -f lavfi -i nullsrc=s=256x144:d=0.1 \
         -c:v h264_nvenc -f null - >"$CCG_LOG/nvenc-test.log" 2>&1; then
      DETECTED=nvenc; ok "NVENC test: PASS (ffmpeg encode thanh cong)"
    else
      warn "NVENC test: FAIL — $(tail -2 "$CCG_LOG/nvenc-test.log" | tr '\n' ' ')"
      if [ -n "$NVENC_LIB" ]; then
        warn "Van giu nvenc vi tim thay $NVENC_LIB (ffmpeg cua Colab co the khong build kem nvenc)"
        DETECTED=nvenc
      else
        DETECTED=software
      fi
    fi
  fi

  [ "$DETECTED" = software ] && \
    warn "Co GPU nhung khong dung duoc NVENC. Kiem tra: nvidia-smi -q -d ENCODER_STATS"

elif [ -e /dev/dri/renderD128 ]; then
  apt_q vainfo intel-media-va-driver mesa-va-drivers
  vainfo 2>/dev/null | grep -qi "VAEntrypointEncSlice" && DETECTED=vaapi
fi

[ "${ENCODER:-auto}" = "auto" ] && ENCODER=$DETECTED
if [ "${CODEC:-auto}" = "auto" ]; then
  case "$ENCODER" in nvenc|vaapi) CODEC=hevc ;; *) CODEC=h264 ;; esac
fi

{ echo "ENCODER=$ENCODER"; echo "CODEC=$CODEC"; echo "NVENC_LIB=${NVENC_LIB:-}"; } >>"$CCG_HOME/encoder.env"
mark ENCODER "$ENCODER"
ok "Encoder = $ENCODER | Codec = $CODEC"
if [ "$ENCODER" = software ]; then
  warn "Dang dung CPU encode -> nen chon 1280x720@60 va bitrate <=10 Mbps"
  warn "Neu ban CHAC CHAN co T4: chay lai cell voi ENCODER=nvenc de ep dung GPU"
fi
