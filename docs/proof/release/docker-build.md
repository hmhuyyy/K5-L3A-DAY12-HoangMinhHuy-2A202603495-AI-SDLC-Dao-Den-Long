# Evidence — Task C: Docker Image (`dao-den-long:1.0.0`)

## 1. Những gì đã kiểm tra
- Kiểm tra Docker CLI và Docker daemon trên máy Windows hiện tại:
  ```powershell
  Get-Command docker -ErrorAction SilentlyContinue
  ```
  → Kết quả: **Không tìm thấy `docker.exe`** trong `PATH` hoặc trong `C:\Program Files\Docker`.
- Đối chiếu [Dockerfile](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/Dockerfile) tại thư mục gốc repository với Godot 4.7.2 và cấu trúc dự án thực tế:
  - Base image: `ubuntu:24.04`.
  - Tải đúng bản chính thức `Godot_v4.7.2-stable_linux.x86_64.zip` từ GitHub Releases của `godotengine/godot`, cài vào `/usr/local/bin/godot`.
  - Đặt `ENV GODOT_BIN=/usr/local/bin/godot` khớp với biến môi trường `GODOT_BIN` được sử dụng trong `tests/run_tests.sh` và `tests/perf_bench.py`.
  - `CMD ["bash", "tests/run_tests.sh"]` tự động chạy `--import` (nếu thiếu `.godot/global_script_class_cache.cfg`) và thực thi toàn bộ 283 bài kiểm thử headless + unit + CLI.

## 2. Hướng dẫn Build & Chạy Container khi có Docker Daemon
Trên máy có cài đặt Docker Desktop (Windows/macOS) hoặc Docker Engine (Linux):

```bash
# 1. Build image dao-den-long:1.0.0
docker build -t dao-den-long:1.0.0 .

# 2. Chạy toàn bộ 283 bài kiểm thử hồi quy headless trong container
docker run --rm dao-den-long:1.0.0

# 3. Chạy headless simulation hoặc 10-night soak test trong container
docker run --rm dao-den-long:1.0.0 godot --headless --path . --script res://src/soak.gd -- --seed 7 --nights 10 --out /tmp/soak.json
```

## 3. Trạng thái
- **Status:** **BLOCKED** (Máy hiện tại không cài đặt Docker CLI / Docker daemon nên không thể thực thi lệnh `docker build` và `docker run` trực tiếp; `Dockerfile` đã được kiểm tra khớp hoàn toàn với Godot 4.7.2 và cấu trúc dự án).
