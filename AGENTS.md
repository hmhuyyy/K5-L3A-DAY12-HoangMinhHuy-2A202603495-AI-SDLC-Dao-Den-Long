# AGENTS.md — Harness cho AI agent (Phase 2)

> Dự án: Đảo Đèn Lồng — game 3D Godot 4.7. Tag Phase 2: `phase-2` (nhánh `phase-2`).
> Nguồn sự thật: `docs/spec/TICKET-02.md` (Phase 2), `docs/spec/PRD-0.md` (Phase 1), `game.contract.json` (tuning v1.1).
> Phân tích đầy đủ: `docs/notes/assumptions.md`.

---

## Lệnh

**Chạy game (có giao diện):**
```
godot --path .
```

**Headless (Test Contract v1.1):**
```
godot --headless --path . --script res://src/headless.gd -- \
  --seed 42 --night 1 --ticks 18000 --out out/result.jsonl
```
Tham số: `--seed <int>`, `--night <1|2|3>`, `--ticks <int>`, `--out <file.jsonl>`,
optional `--scenario <file.json>`, optional `--inputs <file.json>`, optional `--snapshot-every <int>` (mặc định 10).
KHÔNG phát minh flag thêm.

**Test suite:**
```
bash tests/run_tests.sh
```
Exit non-zero nếu bất kỳ test nào fail. Pre-commit hook chạy lệnh này.

**Benchmark hiệu năng:**
```
python3 tests/perf_bench.py
```
Chạy 3 lần cho từng Đêm (18.000 / 19.800 / 21.600 tick); pass khi tất cả 3 lần ≤ 30 s.

---

## Kiến trúc — BẮT BUỘC

- `src/core/` và `src/headless/` KHÔNG import `Node3D`, `Camera3D`, `Viewport`, `RenderingServer`.
- `GameSim` là shared deterministic simulation. Cả 3D và headless dùng **cùng** `GameSim`.
- Tuning load từ `game.contract.json` qua `Config.gd`. KHÔNG hardcode hằng số trùng lặp.
- `Config.gd` có helper `night_duration_s(n)` và `night_shade_speed(n)`.

## RNG — BẮT BUỘC

- MỘT `RandomNumberGenerator`, seed từ `--seed`. KHÔNG gọi `randf()`/`randi()` toàn cục.
- Auto-generated IDs deterministic: S1,S2,… · D1,D2,… · C1,C2 · M1,M2,…

## World angle — BẮT BUỘC

- Mọi góc bản đồ dùng: `x = r·cos(a), z = r·sin(a)`, 0°=+X, 90°=+Z (CCW nhìn từ trên).
- `wind.dir_deg` dùng quy ước này.
- Camera yaw (công thức PRD-0) là **hệ riêng biệt**; KHÔNG dùng chung helper.

## Tick model — BẮT BUỘC

- 60 tick/s. `executed_ticks` tăng mọi lúc. `sim_tick` đứng yên khi pause.
- Thứ tự 12 bước trong `assumptions.md §P2.4`. Terminal priority: `no_flames` > `all_lit` > `dawn`.
- Snapshot: `tick = executed_ticks`, `sim_tick = sim_tick`. Cadence theo `executed_ticks`.
- End record: `ticks = executed_ticks`; `state = "playing"` khi hết ticks trong pause.

## Output JSONL — BẮT BUỘC (Contract v1.1)

- Ba record type: `snapshot`, `event`, `end`.
- Event names chính xác (Phase 1 + mới): `mote_picked`, `deposit`, `lantern_lit`, `pulse`,
  `player_hit`, `shade_spawned`, `game_over`,
  `dash`, `charm_picked`, `drifter_steal`, `drifter_drop`, `night_start`, `paused`, `resumed`.
- Trạng thái Shade bắt buộc: `spawning`, `wander`, `chase`, `recoil`, `stunned`.
- Snapshot v1.1 bắt buộc: `night`, `wind {active, dir_deg}`, `player.{vel, grounded, invuln, dash_cd_s, pulse_cd_s, charm_s}`,
  `motes[].{id, pos, kind, ttl_s}`, `drifters[].{id, pos, state, stolen}`, `charms[].{id, available, respawn_s}`.
- Tọa độ 3 chữ số thập phân. UTF-8, no BOM, LF.
- Scenario setup KHÔNG phát event, KHÔNG cộng điểm.

## Điểm Phase 2 — BẮT BUỘC

- +10 khi **NẠP** đom đóm (deposit), KHÔNG phải khi nhặt.
- +5 mỗi Bóng Mực trúng Tỏa Sáng (kể cả đang choáng).
- Thắng: `floor(time_left_s) × 2 + 50 × flames`.

## Cấm

- `randf()`/`randi()` ngoài `RNG.gd`.
- Hardcode đường dẫn Windows tuyệt đối.
- `Node3D`/`Camera3D`/`Viewport` trong `src/core/`.
- Phát minh CLI flag ngoài contract.
- Đổi tuning ở code mà không cập nhật `game.contract.json`.
- Sửa tag `phase-1` hoặc force push sau khi tag.
- Sửa `GameSim.gd`, `src/gameplay/`, `tests/`, `src/headless/` trong Giai đoạn 0.
- Tự đánh dấu giả định OPEN là đã được duyệt.

## Hook

- Pre-commit: `bash tests/run_tests.sh`. Không commit khi test đỏ.

## Thứ tự triển khai

Giai đoạn 0 (hiện tại): contract + config + assumptions + agents.
Giai đoạn 1: Entities.gd, InputState.gd, WorldDefs.gd, Physics.gd (không sửa GameSim).
Giai đoạn 2: GameSim viết lại (tick order mới, multi-night).
Giai đoạn 3: headless pipeline cập nhật + test suite.
Giai đoạn 4: 3D view (sau khi headless xanh).
Giai đoạn 5: phát hành.

## Tự do sáng tạo

- Thực thể thêm phải TẮT khi chạy headless (không đổi output theo contract).
- Ghi mục "Sáng tạo của tôi" trong README.
