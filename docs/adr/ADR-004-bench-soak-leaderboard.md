# ADR-004 — Benchmark 3D, Soak 10 Đêm, Leaderboard Local & Accessibility (Contract v1.3)

- Trạng thái: Chấp nhận · Phase 4 · Mở rộng Contract v1.2 lên v1.3
- Nguồn: `docs/spec/TICKET-04.md`, `game.contract.json` v1.3

## 1. Bối cảnh

TICKET-04 nâng dự án lên bản phát hành `v1.0.0` (Contract `v1.3`) với bốn nhóm yêu cầu mới:
1. `bench_cmd`: cảnh benchmark 3D 1280×720 với 200 Shade wander, 100 mote, L1–L3 sáng fuel=100, camera quỹ đạo R=30 m, Y=15 m, 15 s/vòng CCW, warm-up 3 s, đo `duration` giây.
2. `soak_cmd`: chạy 10 Night liên tiếp trong cùng một process (`1 -> 2 -> 3 -> 1...`, seed `base_seed + i`), random input theo phân phối xác định, kiểm tra không crash và không rò rỉ bộ nhớ (`mem_end_mb <= 1.2 * mem_start_mb`).
3. Leaderboard local (top 10, validate tên `3–12` ký tự `[A-Za-z0-9_]`, chịu lỗi file hỏng, CLI `--export-leaderboard out.json`).
4. Hệ thống trợ năng (Key remapping cho 9 hành động + phát hiện trùng phím + khôi phục mặc định, chỉ báo hình ảnh & mũi tên Shade ngoài màn hình, Reduce motion, Font tối thiểu 18 px và tùy chọn ×1.25).

## 2. Quyết định kỹ thuật

### 2.1. PRNG và thứ tự tiêu thụ RNG trong Soak Test (`SoakRunner.gd`)
- Mỗi Night thứ `i` (`i = 0..nights-1`) chạy Night `(i % 3) + 1` với `night_seed = base_seed + i`.
- `GameSim` dùng `SimRNG` riêng được seed bằng `night_seed`.
- Luồng sinh input ngẫu nhiên dùng một instance `RandomNumberGenerator` độc lập (`irng.seed = night_seed`) để việc tiêu thụ RNG của bộ sinh input không làm xáo trộn chuỗi RNG của simulation.
- Ở mỗi tick `k` (`k = 0, 1, ...`):
  1. Nếu `k % 30 == 0`: rút **1** số `u_dir = irng.randf()` → góc `a = u_dir * TAU`, hướng `move = (cos(a), sin(a))`.
  2. Rút chính xác **4** số theo thứ tự cố định:
     - `jump = irng.randf() < 0.05`
     - `dash = irng.randf() < 0.03`
     - `pulse = irng.randf() < 0.02`
     - `interact = irng.randf() < 0.10`
- Cả 10 Night chạy tuần tự trong cùng một `SceneTree` process (`src/soak.gd`), tuyệt đối không sinh subprocess.
- `mem_start_mb` được đo ngay sau khi Night đầu tiên khởi tạo xong (`on_loaded` callback), và `mem_end_mb` được đo sau khi Night cuối cùng kết thúc và giải phóng state.

### 2.2. Cảnh Benchmark (`src/bench.gd`, `GameSim.init_bench`, `BenchStats.gd`)
- `GameSim.init_bench(cfg, seed)` khởi tạo Night 1 với L1–L3 `lit=true, fuel=100`, L4–L5 tắt, sau đó dùng `SimRNG(seed)` sinh đều theo diện tích hình tròn (`r = R * sqrt(u), a = v * TAU`) chính xác 200 Shade `wander` (ngoài safe zone) và 100 mote.
- Khi `bench_mode = true`, `GameSim.tick()` chỉ cập nhật chuyển động tuần tra `wander` deterministic của 200 Shade trên mặt đảo; tắt hoàn toàn spawn, damage, pickup, fuel decay và điều kiện kết thúc.
- `load_ms` được ghi nhận bằng `Time.get_ticks_msec()` tại frame đầu tiên của `bench.gd` (tính từ thời điểm engine process khởi động).
- Sau `3.0 s` warm-up, mỗi frame ghi `dt_ms = delta * 1000.0` cho đến khi tổng thời gian đo đạt `duration`.
- Công thức thống kê trong `BenchStats.compute(dts_ms)`:
  - `N = dts_ms.size()`
  - `avg_fps = round(1000.0 * N / sum(dt_i), 0.1)`
  - `k = max(1, ceil(0.01 * N))`
  - `p1_low_fps = round(1000.0 / mean(k giá trị dt_i lớn nhất), 0.1)`
  - `frame_ms_p95 = round(sorted_asc[clamp(ceil(0.95 * N) - 1, 0, N - 1)], 0.1)`

### 2.3. Leaderboard Local (`Leaderboard.gd`) & CLI Export
- Lưu tại `user://leaderboard.json` dưới dạng `{"entries": [...]}`.
- Khi load từ đĩa, nếu file không tồn tại hoặc JSON hỏng, `load_entries()` trả về `[]` an toàn, không làm crash game. Mọi phần tử không hợp lệ trong mảng `entries` bị loại bỏ trước khi sắp xếp.
- Sắp xếp: `score` giảm dần; nếu bằng điểm thì so sánh `iso_to_unix(achieved_at)` tăng dần (người đạt trước đứng trước); nếu vẫn bằng thì giữ thứ tự gốc. Cắt đúng top 10.
- Khi `GameScene._ready()` phát hiện cờ `--export-leaderboard <out.json>` trên dòng lệnh, game xuất ngay file JSON `{"entries": [...]}` theo thứ tự xếp hạng rồi thoát với mã `0`.

### 2.4. Accessibility & Key Remapping (`GameSettings.gd`)
- Lưu tại `user://settings.json`, gồm `colorblind`, `reduce_motion`, `large_font` và `bindings` cho 9 hành động (`move_up`, `move_down`, `move_left`, `move_right`, `jump`, `dash`, `interact`, `pulse`, `pause`).
- `rebind(action, keycode)` kiểm tra trùng phím trên toàn bộ 8 hành động còn lại; nếu trùng thì trả về mã hành động bị trùng và giữ nguyên binding cũ.
- `font_size(base)` đảm bảo cỡ chữ tối thiểu `18 px` ở `1280×720`, và nhân `1.25` (`23 px`) khi bật `large_font`.
