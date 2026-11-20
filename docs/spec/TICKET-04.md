# TICKET-04 — "Bình Minh, Release v1.0.0" (Phase 4)

Loại: Release · Ưu tiên: Cao · Tag nộp: `phase-4` · GitHub Release: `v1.0.0` · Contract: v1.3

## Bối cảnh

Sau Phase 1–3, toàn bộ mechanics cốt lõi của Đảo Đèn Lồng (3 Đêm, nhiên liệu đèn, Bóng Mực hút dầu, sống sót đến bình minh) đã ổn định. Ticket này nâng cấp contract lên `v1.3`, bổ sung benchmark 3D tiêu chuẩn, soak test 10 Đêm liên tiếp trong cùng process, bảng xếp hạng local (top 10 + export CLI), hệ thống trợ năng (remap phím, chỉ báo hình ảnh, giảm chuyển động, chữ lớn), đóng gói và phát hành `v1.0.0`.

Mọi yêu cầu không bị thay thế từ v1.0–v1.2 giữ nguyên.

---

## 1. Test Contract v1.3

- `contract_version: "1.3"`.
- `game.contract.json` có thêm `bench_cmd` và `soak_cmd`.
- Mọi yêu cầu v1.0–v1.2 còn hiệu lực.
- Test ẩn Phase 1–3 không bị thay thế phải tiếp tục đạt.

---

## 2. Benchmark (`bench_cmd`)

Lệnh:

```bash
<bench_cmd> --seed 42 --duration 30 --out bench.json
```

Cảnh benchmark:
- Window 1280×720, không fullscreen.
- Tắt VSync nếu engine hỗ trợ; nếu không hỗ trợ, ghi rõ trong README và output.
- Night 1, đầy đủ hiệu ứng và ánh sáng.
- Chính xác 200 Shade trạng thái `wander`, phân bố đều trên đảo, seed 42.
- Chính xác 100 mote.
- 3 đèn L1–L3 sáng, `fuel=100`.
- Cho phép vượt cap gameplay.
- Tắt spawn, damage, pickup, fuel decay, điều kiện kết thúc.
- Shade vẫn di chuyển wander bình thường.
- Không input player; player đứng tại `(0,0,0)`.
- Camera bay vòng quanh: tâm `(0,0,0)`, bán kính 30 m, `Y=15 m`, look-at origin, start angle `0°` tại `(30,15,0)`, quay ngược chiều kim đồng hồ nhìn từ trên xuống, 15 s/vòng.
- Warm-up 3 giây không đo.
- Đo chính xác `duration` giây rồi tự thoát mã 0.

Output JSON (`bench.json`):

```json
{
  "contract_version": "1.3",
  "avg_fps": 87.3,
  "p1_low_fps": 52.1,
  "frame_ms_p95": 14.2,
  "frames": 2619,
  "load_ms": 2400,
  "peak_mem_mb": 512,
  "vsync_off": true,
  "renderer": "engine/renderer/version",
  "os": "operating system"
}
```

Công thức:
- `N` = số frame trong khoảng đo.
- `avg_fps = 1000 * N / sum(dt_i)`.
- `k = max(1, ceil(0.01 * N))`.
- `p1_low_fps = 1000 / trung_bình(k dt lớn nhất)`.
- `frame_ms_p95` = percentile 95 của `dt`.
- `load_ms` = từ lúc process bắt đầu đến frame đầu tiên của bench.
- `peak_mem_mb` = RSS / working-set cao nhất trong lúc đo.

Ngưỡng máy chấm: `avg_fps >= 60`, `p1_low_fps >= 30`, `load_ms <= 10000`.

---

## 3. Soak Test (`soak_cmd`)

Lệnh:

```bash
<soak_cmd> --seed 7 --nights 10 --out soak.json
```

Yêu cầu:
- 10 Night liên tiếp trong **cùng một process** (không mở 10 subprocess).
- Chu kỳ Night: `1 -> 2 -> 3 -> 1...`
- Night thứ `i` (`i = 0..nights-1`) dùng seed `seed + i`.
- Mỗi Night chạy đến terminal hoặc hết duration chuẩn.
- Random input deterministic:
  - Mỗi 30 ticks chọn lại hướng.
  - Mỗi tick: 5% jump, 3% dash, 2% pulse, 10% interact.
- `mem_start_mb`: RSS sau khi load xong Night đầu.
- `mem_end_mb`: RSS sau khi reset xong Night cuối.

Output JSON (`soak.json`):

```json
{
  "nights": 10,
  "crashes": 0,
  "results": ["lost", "won", "lost"],
  "mem_start_mb": 120,
  "mem_end_mb": 131,
  "duration_s": 84.2
}
```

Ngưỡng: `crashes = 0`, `mem_end_mb <= 1.2 * mem_start_mb`.

---

## 4. Leaderboard Local

Sau màn hình Bình minh khi thắng Night 3 hoặc thua bất kỳ Night nào: cho nhập tên và lưu điểm.

- Name: 3–12 ký tự `[A-Za-z0-9_]`.
- Entry: `{name, score, nights_won, achieved_at (ISO-8601 có timezone), seed}`.
- `score` = tổng điểm campaign của các Night đã thắng.
- Giữ top 10, sắp xếp `score` giảm dần, bằng điểm thì người đạt trước đứng trước.
- Lưu bền vững trên đĩa, validate khi load, file hỏng không làm crash game.
- Có màn hình Leaderboard từ menu chính.
- CLI export: `<run_cmd> --export-leaderboard out.json` xuất `{"entries": [...]}` đúng thứ tự hạng.

---

## 5. Accessibility

- **Key remapping:** Move up/down/left/right, Jump, Dash, Interact, Pulse, Pause. Phát hiện trùng phím, cảnh báo, khôi phục mặc định, lưu/load.
- **Visual indicators:** Shade xuất hiện, mũi tên chỉ hướng Shade ở mép màn hình khi ngoài viewport, gió sắp thổi, 10 giây cuối, đèn `fuel < 30`.
- **Reduce motion:** Tắt camera shake, tắt screen flash, vẫn có chỉ báo thay thế.
- **Font:** Tối thiểu 18 px ở 1280×720, tùy chọn chữ lớn `x1.25`, không tràn hoặc che HUD.

---

## 6. Packaging, Documentation & Release

- Clone mới → tối đa 3 lệnh trong `README.md` là chơi được.
- `README.md`, `CHANGELOG.md` (đủ Phase 1–4), `CREDITS.md`, `LICENSE`, `bench.json`, `soak.json`, Retro 1–2 trang (`docs/retro/RETRO.md`), Demo MP4 dưới 5 phút (hoặc script/checklist + báo rõ blocker nếu môi trường thiếu công cụ ghi hình/export templates).
- Tag `phase-4`, GitHub Release `v1.0.0`.
