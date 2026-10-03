<h1 align="center">🎮 Colab-CG-DATT</h1>
<p align="center">
  <b>Máy ảo Linux XFCE cloud-gaming miễn phí trên Google Colab</b><br>
  Sunshine + Moonlight Web + Cloudflare Tunnel — tối ưu <b>độ trễ thấp</b>
</p>
<p align="center">
  <a href="https://colab.research.google.com/github/tiensdattnek-ai/colab-cg-datt/blob/main/Colab_CG_DATT.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg"></a>
</p>

---

## ⚡ Bắt đầu trong 3 bước
1. Bấm nút **Open in Colab** ở trên → `Runtime > Change runtime type > T4 GPU`.
2. Chạy cell ① và ② (5–8 phút) → nhận link `https://xxx.trycloudflare.com`.
3. Mở link, thêm host `localhost`, lấy PIN → dán vào cell ③. Xong, chơi.

## 🚀 Những gì đã tối ưu cho độ trễ

| Lớp | Kỹ thuật | Lợi ích |
|---|---|---|
| **Encode** | Tự dò NVENC → VAAPI → software; `nvenc_preset=1` (P1 ultra-low-latency), `latency_over_power`, tắt two-pass & spatial-AQ, HEVC | −8…15 ms encode |
| **Capture** | Modeline `cvt` khớp đúng res/fps, không scale, `Virtual` = đúng khung | bỏ 1 lần resample |
| **Compositor** | Tắt `use_compositing`, `sync_to_vblank`, animation GTK, DPMS | −1…2 frame |
| **Audio** | PulseAudio `tsched=0`, `fragments=2 × 5ms`, 48 kHz, null-sink riêng | ~10 ms thay vì 40–80 ms |
| **Mạng** | `tcp_bbr` + `fq`, `tcp_notsent_lowat=16384`, `tcp_low_latency`, busy-poll 50 µs, buffer 16 MB | ít bufferbloat, ổn định jitter |
| **Transport** | cloudflared chạy **`--protocol quic`** (UDP) thay vì HTTP/2 | −10…30 ms so với mặc định |
| **Scheduling** | Sunshine/Xorg/Pulse ở `SCHED_FIFO` prio 50, `renice -15`, tắt apt-daily/snapd | hết micro-stutter |
| **GPU** | `nvidia-smi -pm 1`, khoá xung SM tối đa | hết tụt clock giữa trận |
| **Lựa chọn Pro** | `TUNNEL=tailscale` → UDP P2P trực tiếp, bỏ qua edge Cloudflare | thấp nhất có thể |
| **FEC/QP** | `fec_percentage=10`, `qp=24` cân bằng băng thông/độ nét | ít retransmit |

## 🩺 Tự sửa lỗi
```bash
sudo bash scripts/doctor.sh    # chẩn đoán + khởi động lại đúng thành phần chết
sudo bash scripts/80-verify.sh # health check 11 mục
```

### Đã fix ở v2.1.0
| Lỗi | Nguyên nhân thật | Cách xử lý |
|---|---|---|
| `FAIL Cai Sunshine that bai` | GitHub encode `+` thành `%2B` trong URL (`...%2Bubuntu22.04_amd64.deb`) → regex `ubuntu-<ver>` trượt, fallback `sort -V\|tail` tải **nhầm gói arm64 của Ubuntu 26.10** | Resolver khớp đúng distro+version+arch, tụt dần về LTS gần nhất, + 3 lớp dự phòng `.deb → AppImage → Flatpak` |
| Màn hình đen / X không lên | Container không có VT, dummy driver fail | `-novtswitch -sharevts vt1`, xoá `.X0-lock`, **fallback Xvfb** |
| Treo ở bước chờ X | `wait_port 6000` sai — X không listen TCP | `wait_x` kiểm tra socket `/tmp/.X11-unix/X0` |
| App trong Moonlight không mở | `prep-cmd` gọi `xrandr --output default` fail | Bỏ prep-cmd rủi ro |
| Cảnh báo *unrecognized option* | Ghi tham số NVENC khi đang dùng software | Sinh config theo đúng encoder |
| GPU có nhưng không dùng NVENC | Hardcode `libnvidia-encode-535` | Dò driver thật + kiểm tra `ldconfig` |

## 📦 Cấu trúc
```
colab-cg-datt/
├── Colab_CG_DATT.ipynb      # Notebook 1 chạm (form chọn res/fps/encoder/tunnel)
├── config/
│   ├── sunshine.conf.tmpl   # Profile Sunshine low-latency
│   └── apps.json            # App: Desktop / Steam Big Picture / 720p mode
└── scripts/
    ├── install.sh           # Orchestrator một lệnh
    ├── 00-common.sh         # Biến cấu hình + helper
    ├── 10-desktop.sh        # Xorg dummy + XFCE (no compositing)
    ├── 20-audio.sh          # PulseAudio low-latency
    ├── 30-gpu.sh            # Dò NVENC/VAAPI
    ├── 40-sunshine.sh       # Cài + cấu hình Sunshine
    ├── 50-moonweb.sh        # Moonlight Web client
    ├── 60-tunnel.sh         # Cloudflare QUIC / Tailscale
    ├── 70-latency.sh        # Tuning kernel, RT prio, GPU clock
    ├── 80-verify.sh         # Health check 11 mục
    ├── doctor.sh            # Tự chẩn đoán + tự sửa
    ├── pair.sh              # Pair bằng PIN qua API
    ├── status.sh            # Dashboard chẩn đoán
    └── backup.sh            # Backup/restore game ra Google Drive (zstd)
```

## 🛠 Dùng ngoài Colab (VPS / PC Ubuntu)
```bash
git clone https://github.com/tiensdattnek-ai/colab-cg-datt && cd colab-cg-datt
sudo RES_W=1920 RES_H=1080 FPS=60 ENCODER=nvenc CODEC=hevc TUNNEL=cloudflare \
     bash scripts/install.sh
sudo bash scripts/pair.sh 1234     # PIN từ Moonlight
sudo bash scripts/status.sh        # xem trạng thái + RTT + GPU
sudo bash scripts/doctor.sh        # khi có trục trặc
```

### Biến môi trường
| Biến | Mặc định | Ghi chú |
|---|---|---|
| `RES_W` / `RES_H` | 1920 / 1080 | độ phân giải ảo |
| `FPS` | 60 | 30 / 60 / 120 |
| `ENCODER` | auto | `nvenc` \| `vaapi` \| `software` |
| `CODEC` | auto | `h264` \| `hevc` \| `av1` |
| `TUNNEL` | cloudflare | `tailscale` (thấp trễ nhất) \| `none` |
| `LOWLAT` | 1 | 0 = tắt mọi tuning |
| `WEB_PORT` | 8080 | cổng Moonlight Web |
| `QP` / `FEC` | 24 / 10 | chất lượng & chống mất gói |
| `TS_AUTHKEY` | – | auth key Tailscale (không cần login tay) |

## 🎯 Cài đặt khuyến nghị phía client (Moonlight)
- Bitrate **20–30 Mbps** (Wi-Fi 5GHz/dây), **15 Mbps** nếu mạng yếu
- **HEVC: ON**, V-Sync: **OFF**, Frame pacing: **OFF**
- Resolution client = resolution host (tránh scale 2 lần)

## 🩺 Khắc phục sự cố
| Triệu chứng | Cách xử lý |
|---|---|
| Cài Sunshine lỗi | Đã fix ở v2.1; nếu vẫn lỗi: `sudo bash scripts/doctor.sh`, script sẽ tự chuyển sang AppImage |
| Không có link `trycloudflare` | `sudo tail -f /var/log/ccg/cf-web.log`, chạy lại cell ② |
| Pair báo false | PIN hết hạn (60s) — lấy PIN mới |
| Màn hình đen | `sudo tail /var/log/ccg/xorg.log`; thử res thấp hơn |
| Không có tiếng | `pactl list short sinks` phải thấy `ccg`; chạy lại `20-audio.sh` |
| Giật/tụt frame | Hạ `1600x900@60`, `ENCODER=nvenc`, bitrate 15 Mbps |
| Mất hết sau khi ngắt | Dùng cell ⑥ backup ra Drive |

## ⚠️ Cảnh báo pháp lý
Google Colab **cấm** dùng runtime cho remote desktop, game streaming, P2P, mining. Tài khoản có thể bị hạn chế GPU. Repo này dành cho **học tập/nghiên cứu**, bạn tự chịu rủi ro. Phương án hợp lệ: VPS GPU trả phí, Paperspace, Oracle Cloud free tier (CPU), hoặc tự host Sunshine trên PC nhà — cùng bộ script này chạy được hết.

## 🙏 Nguồn tham khảo
[LizardByte/Sunshine](https://github.com/LizardByte/Sunshine) · [kmille36/Colab-Cloud-Gaming](https://github.com/kmille36/Colab-Cloud-Gaming) · [kmille36/moonlight-web-remote](https://github.com/kmille36/moonlight-web-remote) · [cloudflared](https://github.com/cloudflare/cloudflared)

## 📜 Changelog
Xem [CHANGELOG.md](CHANGELOG.md) — v2.1.0 fix lỗi cài Sunshine + hardening.

## 📄 License
MIT © tiensdattnek-ai
