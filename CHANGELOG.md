# Changelog

## v2.1.0 — Hotfix "Cai Sunshine that bai" + hardening
### 🐞 Sửa lỗi
- **[CRITICAL] Cài Sunshine thất bại**: tên asset GitHub là `...%2Bubuntu22.04_amd64.deb`
  (dấu `+` bị URL-encode), regex cũ `ubuntu-<ver>` không khớp → fallback `sort -V | tail -1`
  tải nhầm **gói arm64 của Ubuntu 26.10** → `dpkg` fail. Đã thay bằng **resolver thật**:
  khớp đúng `distro + version + kiến trúc`, tụt dần về bản Ubuntu LTS gần nhất ≤ phiên bản hiện tại.
- Thêm **3 lớp dự phòng**: `.deb` → `apt --fix-broken` → **AppImage** (tự giải nén, không cần FUSE) → **Flatpak**.
- **Xorg trong container**: thêm `-novtswitch -sharevts vt1`, xoá `/tmp/.X0-lock`, **fallback sang Xvfb** nếu dummy driver fail.
- `wait_port 6000` sai (X không listen TCP) → thay bằng `wait_x` kiểm tra socket `/tmp/.X11-unix/X0` + `xdpyinfo`.
- `30-gpu.sh` không còn hardcode `libnvidia-encode-535`; dò driver thật, kiểm tra `ldconfig` trước khi chọn NVENC.
- `sunshine.conf` chỉ ghi tham số của đúng encoder đang dùng (hết cảnh báo *unrecognized option*);
  thêm `sw_preset=superfast / sw_tune=zerolatency` cho chế độ software.
- `apps.json`: bỏ `prep-cmd` gọi `xrandr --output default` (fail → không khởi chạy được app).
- Sunshine chạy fallback bằng root nếu user thường không mở được cổng 47990.
- `install.sh` không còn `die` giữa chừng: mỗi bước **tự thử lại 1 lần**, bước không bắt buộc thì bỏ qua và báo rõ.

### ✨ Thêm mới
- `scripts/80-verify.sh` — health check 11 mục (X, WM, audio sink, cổng 47989/47990, tunnel, BBR…).
- `scripts/doctor.sh` — **tự chẩn đoán và sửa**: khởi động lại đúng thành phần chết, in link + log liên quan.
- Cell "🩺 Doctor" trong notebook.
- `dl()` tải có retry (curl → wget), `mark()` ghi trạng thái vào `/opt/ccg/state.env`.
- Kiểm chứng desktop thật sự lên, fallback `xfwm4 + xfdesktop` nếu `xfce4-session` chết.

## v2.0.0 — Bản Pro
- Kiến trúc module 8 script, notebook dạng form, tuning độ trễ toàn diện
  (NVENC P1, no-compositing, Pulse 10ms, BBR+fq, cloudflared QUIC, RT priority, GPU clock lock),
  `status.sh`, `backup.sh` (zstd → Google Drive), chế độ Tailscale.

## v1.0.0 — Bản đầu
- XFCE + Sunshine + Moonlight Web + Cloudflare Tunnel trên Colab.
