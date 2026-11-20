# DEMO VIDEO SCRIPT & CHECKLIST (< 5 phút) — Đảo Đèn Lồng v1.0.0

> Tài liệu kịch bản quay video demo thực tế (`< 5 phút`) cho bản phát hành `v1.0.0` (Phase 4).

## 1. Cấu hình ghi hình
- Độ phân giải: `1280×720` (Windowed), 60 FPS, định dạng `MP4 (H.264)`.
- Công cụ ghi hình khuyến nghị trên Windows: OBS Studio hoặc Windows Game Bar (`Win + Alt + R`), hoặc dùng chế độ `--write-movie` của Godot khi có `ffmpeg` / MJPEG:
  ```bash
  godot --path . --write-movie out/demo_raw.avi --fixed-fps 60 --quit-after 1800
  ```

## 2. Kịch bản phân cảnh (Tổng thời lượng: ~3 phút 45 giây)

### Phần 1 — Giới thiệu & Khởi chạy trong 3 lệnh (0:00 – 0:30)
1. Mở terminal tại thư mục gốc repository.
2. Hiển thị `game.contract.json` (`contract_version: "1.3"`, `run_cmd`, `headless_cmd`, `bench_cmd`, `soak_cmd`).
3. Chạy `godot --path .` mở màn hình game 3D ở độ phân giải `1280×720`.

### Phần 2 — Gameplay thực tế, Nhiên liệu đèn, Shade Drain & Trợ năng (0:30 – 2:00)
1. **HUD & Đêm 1 (Đảo Bến):** Chỉ rõ HUD hiển thị `Đom đóm: carried / capacity (0 / 10)`, số đèn sáng cần đạt (`3/5`), Ngọn Lửa (`3`), điểm số và thời gian đếm ngược (240s).
2. **Nhặt đom đóm & Thắp đèn lần đầu (10 mote):** Di chuyển Mây (`WASD`), nhảy (`Space`), lướt (`Shift`), nhấn `E` nạp đom đóm vào đèn `L1` → đèn sáng (`fuel = 100`), thanh nhiên liệu 3D xuất hiện trên đỉnh đèn, sức chứa tăng từ `10` lên `12`.
3. **Bóng Mực hút dầu (`drain`) & Tỏa Sáng (`Q`):** Khi đèn giảm xuống `fuel < 30`, đèn nhấp nháy 1 Hz, cảnh báo `⚠ Đèn sắp cạn dầu (<30)` hiện trên HUD và mũi tên `⚠ Bóng Mực` chỉ hướng ở mép màn hình. Nhấn `Q` (Tỏa Sáng) làm choáng Bóng Mực (+15 điểm nếu đang drain) và nhấn `E` châm dầu (`refuel`) đẩy Bóng Mực ra rìa vùng an toàn 6m.
4. **Menu Cài đặt & Trợ năng:** Mở `Cài đặt`, bật **"Bảng màu dễ phân biệt"** (Bóng Mực chuyển từ `#7A3CFF` sang `#00B3FF`, cảnh báo `#FFFFFF` kèm `⚠`; đèn tắt xẹp 20% kèm vết giấy rách), bật **"Giảm chuyển động"** và **"Chữ lớn ×1.25"**, thử gán trùng phím để thấy thông báo phát hiện trùng phím rồi nhấn **"Khôi phục mặc định"**.
5. **Bảng xếp hạng (Leaderboard):** Mở `Bảng xếp hạng` xem Top 10 local.

### Phần 3 — Bằng chứng Automated Tests & Headless Pipeline (2:00 – 2:50)
1. Chạy bộ kiểm thử hồi quy Phase 1–4:
   ```bash
   bash tests/run_tests.sh
   ```
   Hiển thị kết quả toàn bộ 280+ assertions `PASS` (`0 failed`).
2. Chạy headless CLI cho Đêm 1, 2, 3:
   ```bash
   godot --headless --path . --script res://src/headless.gd -- --seed 42 --night 1 --ticks 600 --out out/demo_n1.jsonl
   ```
   Mở `out/demo_n1.jsonl` chỉ rõ 3 loại bản ghi `snapshot`, `event`, `end` đúng schema v1.2/v1.3.

### Phần 4 — Benchmark 3D & Soak Test 10 Đêm (2:50 – 3:45)
1. Chạy cảnh Benchmark 3D (200 Shade wander, 100 mote, L1–L3 lit, camera bay vòng quanh đảo R=30m, Y=15m):
   ```bash
   godot --path . --script res://src/bench.gd -- --seed 42 --duration 30 --out bench.json
   ```
   Hiển thị `bench.json` (`avg_fps >= 60`, `p1_low_fps >= 30`, `load_ms <= 10000`).
2. Chạy Soak Test 10 Đêm liên tiếp trong cùng một process:
   ```bash
   godot --headless --path . --script res://src/soak.gd -- --seed 7 --nights 10 --out soak.json
   ```
   Hiển thị `soak.json` (`crashes: 0`, `mem_end_mb <= 1.2 * mem_start_mb`).
