#!/usr/bin/env bash
# Tinh chinh kernel/network/CPU cho do tre thap nhat
source "$(dirname "$0")/00-common.sh"
[ "$LOWLAT" = "1" ] || { warn "LOWLAT=0, bo qua tuning"; exit 0; }
say "Tinh chinh he thong cho do tre thap"

# --- Network: BBR + fq, buffer lon, giam bufferbloat ---
modprobe tcp_bbr 2>/dev/null || true
cat >/etc/sysctl.d/99-ccg.conf <<'SYS'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.netdev_max_backlog = 5000
net.core.busy_poll = 50
net.core.busy_read = 50
SYS
sysctl -p /etc/sysctl.d/99-ccg.conf >/dev/null 2>&1 || true

# --- CPU governor performance (neu co quyen) ---
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  [ -w "$g" ] && echo performance > "$g" 2>/dev/null || true
done

# --- Uu tien tien trinh stream ---
cat >/usr/local/bin/ccg-prio <<'PRIO'
#!/usr/bin/env bash
for p in sunshine Xorg pulseaudio colab-moonweb cloudflared; do
  for pid in $(pgrep -x "$p" 2>/dev/null); do
    renice -n -15 -p "$pid" >/dev/null 2>&1
    chrt -f -p 50 "$pid" >/dev/null 2>&1 || ionice -c1 -n0 -p "$pid" >/dev/null 2>&1
  done
done
PRIO
chmod +x /usr/local/bin/ccg-prio; /usr/local/bin/ccg-prio

# --- GPU: khoa xung toi da + persistence (NVIDIA) ---
if has_nvidia; then
  nvidia-smi -pm 1 >/dev/null 2>&1 || true
  MAXCLK=$(nvidia-smi --query-supported-clocks=graphics --format=csv,noheader,nounits 2>/dev/null | head -1)
  [ -n "$MAXCLK" ] && nvidia-smi -lgc "$MAXCLK" >/dev/null 2>&1 || true
fi

# --- Giam tre input: tat key repeat delay cao, tang toc con tro ---
DISPLAY=:0 xset r rate 250 40 2>/dev/null || true

# --- Tat dich vu khong can thiet de giam jitter CPU ---
for s in unattended-upgrades apt-daily.timer apt-daily-upgrade.timer snapd man-db.timer; do
  systemctl stop "$s" 2>/dev/null; systemctl disable "$s" 2>/dev/null
done
pkill -f unattended-upgrade 2>/dev/null || true
ok "Da ap dung: BBR+fq, busy-poll, RT priority, GPU clock lock, no-compositing"
