# Changelog

Định dạng theo [Keep a Changelog](https://keepachangelog.com/). Phiên bản contract: v1.0 → v1.1 → v1.2 → v1.3.

## [1.0.0] — Phase 4 · "Bình minh" · Contract v1.3
### Added
- `bench_cmd` / `soak_cmd` trong contract; scene benchmark 200 Shade + 100 mote (`--seed 42 --duration 30 --out bench.json`),
  soak 10 Night cùng process (`--seed 7 --nights 10 --out soak.json`).
- Leaderboard local (top 10, validate, chịu file hỏng, `--export-leaderboard`), màn hình tên + bảng xếp hạng từ menu.
- Accessibility: remap phím (phát hiện trùng, khôi phục mặc định), chỉ báo hình ảnh (Shade, gió, 10 giây cuối, fuel < 30),
  mũi tên Shade ngoài màn hình, giảm chuyển động, font ≥ 18 px + tùy chọn ×1.25.
- README, CREDITS, LICENSE, Retro, evidence Phase 1–4, script build/demo.
### Changed
- Contract `1.3`: thêm `bench_cmd`, `soak_cmd` (mọi yêu cầu v1.0–v1.2 còn hiệu lực).

## [0.3.0] — Phase 3 · "Đèn cạn dầu" · Contract v1.2
### Added
- Nhiên liệu đèn (`fuel`, `ever_lit`, `relit_count`; lưu nội bộ theo 1/60), thắp lại (5 mote), châm dầu (`ceil`).
- Shade hút dầu (state `drain`), event `fuel_drain`, `lantern_out`, `refuel`; `lantern_lit.relight`.
- Capacity `min(20, 10 + 2·successful_lights)`; snapshot `player.capacity`.
- Chế độ "Bảng màu dễ phân biệt" (colorblind) lưu trên đĩa; fuel bar; đèn tắt xẹp + giấy rách; nhấp nháy 1 Hz khi fuel < 30.
- Safe push khi đèn mới thành vùng an toàn; `Config.parse_dict` strict (lỗi có field path).
- ADR-003; `docs/notes/test-migration.md`; bộ unit test GDScript `tests/unit/run_unit.gd`.
### BREAKING CHANGES (contract v1.1 → v1.2)
- Không còn thắng sớm `all_lit`; thắng = `dawn_survived` khi hết giờ với ≥ `ceil(0.6·N)` đèn sáng (N1 3/5, N2 4/6, N3 5/7).
- Thời lượng đêm 300/330/360 s → **240/270/300 s**.
- Điểm: +5/mote nạp (trước 10); thắp lần đầu +100; thắp lại +40; Pulse +5 (+15 nếu Shade đang drain);
  thắng: `Σ(50 + floor(fuel))` + `50·flames`; **bỏ** thưởng `floor(time_left)·2`.
- Đèn sáng cạn dầu sau 100 s nếu không châm; `fuel < 30` mất vùng an toàn.
- Capacity không còn cố định 10.
- `game_over.reason`: bỏ `all_lit`, thêm `dawn_survived`.
- Snapshot: thêm `lanterns[].fuel/ever_lit/relit_count`, `player.capacity`, shade state `drain`.
### Fixed
- Rơi khỏi đảo chỉ trừ 1 Ngọn Lửa (trước đây 2).
- Bộ đếm choáng/recoil theo bước 2; `game_over` không còn bị ghi hai lần.
- `headless.gd` thoát mã 1 khi tham số sai (trước đây chạy với tham số rỗng).

## [0.2.0] — Phase 2 · Contract v1.1
- 3 Đêm (Bến, Cau, Chuông), nhảy/lướt/bục nhảy/gió, Gió Lạc, Bùa Gió, rơi khỏi đảo, pause, tick order 12 bước,
  Shade state machine (`spawning/wander/chase/recoil/stunned`), snapshot v1.1, 34 test.

## [0.1.0] — Phase 1 · Contract v1.0
- Lõi tất định `GameSim`, headless JSONL, 3D passive view, 34 test (tag `phase-1`, bất biến).
