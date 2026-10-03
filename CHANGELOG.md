# Changelog

## v2.2.0 — Fix "không nhận T4 / tự tụt về CPU" + Sunshine không khởi động

### 🎮 GPU / NVENC
- **Nguyên nhân tự tụt về `software`**: Colab mount driver NVIDIA **ngoài ld cache** (`/usr/lib64-nvidia`,
  `/usr/local/nvidia/lib64`), script chỉ kiểm tra `ldconfig -p` nên không thấy `libnvidia-encode` → kết luận "không có GPU encode".
- Nay dò theo **4 tầng**: `ldconfig` (sau khi refresh) → quét 8 thư mục driver phổ biến → `find` toàn hệ thống →
  **test encode thật bằng `ffmpeg -c:v h264_nvenc`**.
- Tự ghi `ld.so.conf.d/zz-ccg-nvidia.conf` + tạo symlink `libnvidia-encode.so.1` nếu thiếu, export `LD_LIBRARY_PATH` cho Sunshine.
- Bỏ cài `libnvidia-encode-535` bằng apt (có thể **phá driver sẵn có** của Colab).
- Chọn `ENCODER=nvenc` thủ công = **ép dùng GPU**, script không tự hạ xuống CPU nữa.
- Thêm `scripts/gpu-check.sh` kiểm tra nhanh trước khi cài; ô ① của notebook báo rõ có/không có T4.

### ☀️ Sunshine không khởi động
- Bật kho `universe` trước khi cài (một số image Colab tắt → thiếu `libqt6*` → cài `.deb` fail).
- Cài sẵn đúng bộ deps thật của gói (`libqt6core6/gui6/widgets6/svg6`, `libminiupnpc17/18`, `libxtst6`, `libvulkan1`…).
- **Kiểm chứng binary chạy được** (`sunshine --version`); nếu báo *error while loading shared libraries* → **tự gỡ deb và chuyển sang AppImage**.
- Tạo `/run/user/<uid>`, `xhost +local:`, `modprobe uinput` + `chmod 0666 /dev/uinput` (báo rõ khi Colab không có uinput).
- Đặt mật khẩu bằng **CLI `sunshine --creds`** thay vì phụ thuộc web API.
- Khởi động theo **3 nấc**: user thường → root → hạ `encoder=software` (loại trừ lỗi NVENC) — thay vì chết ngay.
- Khi fail: in **40 dòng log Sunshine + 15 dòng apt** ngay tại chỗ, kèm gợi ý lệnh kiểm tra X.

### 🧰 Công cụ
- `scripts/collect-logs.sh` — xuất báo cáo đầy đủ (hệ thống, GPU, state, tiến trình, cổng, 6 file log) ra `/content/ccg-report.txt`.
- Ô 🩺 Doctor trong notebook có dropdown: `doctor` / `gpu-check` / `collect-logs` / `verify`.

## v2.1.1 — Fix notebook mất thư mục làm việc
- **Lỗi**: chạy lại cell cài đặt lần 2 → `shell-init: error retrieving current directory`,
  `fatal: Unable to read current working directory`, `bash: scripts/install.sh: No such file`.
  Nguyên nhân: lần chạy trước `%cd /content/colab-cg-datt` đặt cwd vào thư mục đó, cell sau `rm -rf` xoá
  chính thư mục đang đứng → mọi lệnh shell sau đều mất cwd nên `git clone` fail.
- **Fix**: cell cài đặt chuyển sang Python thuần — `os.chdir('/content')` **trước** khi `shutil.rmtree`,
  kiểm chứng `scripts/install.sh` tồn tại, **fallback tải tarball** nếu `git clone` lỗi,
  gọi installer bằng **đường dẫn tuyệt đối** (không phụ thuộc cwd).
- Thêm cell 🧹 **Reset an toàn** để dọn dẹp khi kẹt.

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
