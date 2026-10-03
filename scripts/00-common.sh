#!/usr/bin/env bash
# Shared helpers + config defaults for Colab-CG-DATT
export DEBIAN_FRONTEND=noninteractive
export CCG_HOME="${CCG_HOME:-/opt/ccg}"
export CCG_LOG="${CCG_LOG:-/var/log/ccg}"
export CCG_USER="${CCG_USER:-gamer}"

# ---- Tunables (override bang bien moi truong truoc khi chay install.sh) ----
export RES_W="${RES_W:-1920}"          # do phan giai ngang
export RES_H="${RES_H:-1080}"          # do phan giai doc
export FPS="${FPS:-60}"                # 60 hoac 120
export BITRATE="${BITRATE:-20000}"     # kbps goi y cho client
export CODEC="${CODEC:-auto}"          # auto|h264|hevc|av1
export ENCODER="${ENCODER:-auto}"      # auto|nvenc|vaapi|software
export WEB_PORT="${WEB_PORT:-8080}"    # cong Moonlight Web
export TUNNEL="${TUNNEL:-cloudflare}"  # cloudflare|tailscale|none
export LOWLAT="${LOWLAT:-1}"           # 1 = bat toan bo tinh chinh do tre

mkdir -p "$CCG_HOME" "$CCG_LOG"

c_reset=$'\033[0m'; c_cy=$'\033[1;36m'; c_gn=$'\033[1;32m'; c_yl=$'\033[1;33m'; c_rd=$'\033[1;31m'
say()  { echo -e "${c_cy}==>${c_reset} $*"; }
ok()   { echo -e "${c_gn} ok ${c_reset} $*"; }
warn() { echo -e "${c_yl} !! ${c_reset} $*"; }
die()  { echo -e "${c_rd}FAIL${c_reset} $*"; exit 1; }

as_user() { sudo -u "$CCG_USER" env DISPLAY=:0 \
  XDG_RUNTIME_DIR="/run/user/$(id -u "$CCG_USER")" \
  PULSE_SERVER="unix:/run/user/$(id -u "$CCG_USER")/pulse/native" "$@"; }

apt_q() { apt-get install -y -qq --no-install-recommends "$@" >>"$CCG_LOG/apt.log" 2>&1; }

wait_x() { # doi X socket san sang (X khong lang nghe TCP)
  local d=${1:-0} t=${2:-30} i=0
  while [ ! -S "/tmp/.X11-unix/X$d" ]; do i=$((i+1)); [ "$i" -ge "$t" ] && return 1; sleep 1; done
  DISPLAY=:$d xdpyinfo >/dev/null 2>&1 || sleep 2; return 0
}

dl() { # tai co retry: dl <url> <out>
  curl -fsSL --retry 4 --retry-delay 2 --connect-timeout 15 -o "$2" "$1" && return 0
  wget -q --tries=3 --timeout=20 -O "$2" "$1"
}

wait_port() { # wait_port <port> <timeout_s>
  local p=$1 t=${2:-60} i=0
  while ! (echo >/dev/tcp/127.0.0.1/"$p") 2>/dev/null; do
    i=$((i+1)); [ "$i" -ge "$t" ] && return 1; sleep 1
  done; return 0
}

# Ghi ket qua buoc chay de doctor.sh doc lai
mark() { echo "$1=$2" >> "$CCG_HOME/state.env"; }

has_nvidia() { command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; }
