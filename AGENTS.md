# AGENTS.md — Harness cho AI agent (Phase 1)

> Dự án: Đảo Đèn Lồng — game 3D Godot 4.7. Tag Phase 1: `phase-1`.
> Nguồn sự thật: `docs/spec/PRD-0.md` (PRD-0 + Test Contract v1.0), `game.contract.json` (tuning).

## Lệnh

**Chạy game (có giao diện):**
```
godot --path .
```

**Headless (Test Contract):**
```
godot --headless --path . --script res://src/headless.gd -- --seed 42 --night 1 --ticks 300 --out out/result.jsonl
```
Tham số: `--seed <int>`, `--night <int>`, `--ticks <int>`, `--out <file.jsonl>`, optional `--scenario <file.json>`, optional `--inputs <file.json>`, optional `--snapshot-every <int>` (mặc định 10). KHÔNG phát minh flag thêm.

**Test:**
```
bash tests/run_tests.sh
```
Exit non-zero nếu bất kỳ test nào fail.

## Kiến trúc — BẮT BUỘC

- `src/core/` và `src/headless/` KHÔNG import `Node3D`, `Camera3D`, `Viewport`, `RenderingServer`. Logic game chạy không cần cửa sổ.
- `GameSim` là shared deterministic simulation. Game 3D và headless runner dùng **cùng** `GameSim`.
- Tuning load từ `game.contract.json` qua `Config.gd`. KHÔNG hardcode hằng số trùng lặp có thể drift.

## RNG — BẮT BUỘC

- MỘT `RandomNumberGenerator`, seed từ `--seed`. KHÔNG gọi `randf()`/`randi()` toàn cục. Mọi random qua `RNG.gd`.
- Auto-generated IDs deterministic từ seed.

## Tick model — BẮT BUỘC

- 60 tick/s. `time_left_s = max(0, initial_time_left_s - executed_ticks/60.0)`.
- Snapshot tick 0 = trạng thái sau scenario setup, trước input. `--ticks N` chạy đúng N bước.
- Thứ tự 12 bước trong `assumptions.md` §5. Terminal priority: `no_flames` > `all_lit` > `dawn`.
- End record luôn viết cuối, kể cả khi dừng do đạt tick limit.

## Output JSONL — BẮT BUỘC

- Ba record type: `snapshot`, `event`, `end`. `game_over` là event name.
- Event names chính xác: `mote_picked`, `deposit`, `lantern_lit`, `pulse`, `player_hit`, `shade_spawned`, `game_over`.
- Tọa độ làm tròn 3 chữ số thập phân. UTF-8, no BOM, LF, không khoảng trắng thừa.
- Scenario setup KHÔNG phát event, KHÔNG cộng điểm.

## Cấm

- `randf()`/`randi()` ngoài `RNG.gd`.
- Hardcode đường dẫn Windows tuyệt đối.
- `Node3D`/`Camera3D`/`Viewport` trong `src/core/`.
- Phát minh CLI flag ngoài PRD-0.
- Đổi tuning ở code mà không cập nhật `game.contract.json`.
- Xóa file harness; không force push sau khi tag.

## Hook

- Pre-commit chạy `bash tests/run_tests.sh`. Không commit khi test đỏ.

## Tự do sáng tạo

- Thực thể thêm phải TẮT khi chạy headless (không đổi output theo contract).
- Ghi mục "Sáng tạo của tôi" trong README.
