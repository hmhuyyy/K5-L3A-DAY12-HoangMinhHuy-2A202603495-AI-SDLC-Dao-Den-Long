# Phase 1 Assumptions — Đảo Đèn Lồng

> Quy ước trong file này: **[REQ]** = PRD-0 / Test Contract v1.0 yêu cầu rõ; **[ASSUME]** = quyết định thiết kế tự chọn. Mọi giá trị tuning nằm trong `game.contract.json` (single source of truth).

Cập nhật lần cuối: Phase 1.

---

## 1. Tuning baseline (game.contract.json)

Toàn bộ giá trị trong `game.contract.json` đã được duyệt. Không liệt kê lại ở đây để tránh trùng lặp và drift. File `game.contract.json` là nguồn sự thật duy nhất cho runtime tuning.

Giải thích các trường PRD-0 yêu cầu làm rõ:
- **flames** = máu người chơi (player health).
- **carried** = số đom đóm đang mang.
- **pulse_cost** tiêu thụ **carried motes**, KHÔNG tiêu health.
- **hit_drop_ratio** = tỉ lệ đom đóm đánh rơi khi bị chạm (0 nếu không rơi).
- **safe_radius** = bán kính quanh đèn mà Bóng Mực không vào được.
- **fall_enabled = false** = không phạt rơi khỏi đảo.

---

## 2. Thế giới mặc định [ASSUME]

- **Mote ban đầu:** 25 con, ngẫu nhiên trên đảo (deterministic từ seed), không respawn.
- **Shade ban đầu:** 2 con, đặt deterministic từ seed, xuất hiện trong snapshot tick 0 (không phát `shade_spawned`).
- **Spawn shade động:** mỗi 60 s (3600 tick) thêm 1 shade cho tới tối đa 5. Chỉ các spawn động phát `shade_spawned`.
- **Hình đảo:** tròn, bán kính 40 m, tâm (0,0,0), mặt đất Y=0 — **chỉ yêu cầu thị giác**.
- **Vị trí đèn mặc định L1–L5:** trải đều trên vòng tròn bán kính 25 m quanh tâm.
- **Ranh giới di chuyển trong headless:** KHÔNG clamp. `fall_enabled=false` → rời đảo không phạt, không phát event `player_hit by:"fall"`.

---

## 3. Dropped motes [ASSUME]

Khi `player_hit by:"shade"`:
- `dropped = floor(carried * hit_drop_ratio)`
- `carried -= dropped`
- Tạo `dropped` mote mới trên mặt đất gần vị trí XZ của player (scatter nhỏ deterministic từ seed)
- Gán ID deterministic duy nhất từ bộ đếm mote (`M1`, `M2`, …)
- Dropped motes thu thập lại được theo quy tắc pickup bình thường
- KHÔNG cộng điểm khi rơi; `per_mote` chỉ cộng khi thực sự nhặt

---

## 4. Jump [ASSUME]

- Độ cao nhảy: 1.5 m. Thời gian: 0.8 s = 48 tick.
- Quỹ đạo parabol, đỉnh ở tick 24. Y trong `player.pos[1]`.
- Khi trên không, rising-edge jump mới bị bỏ qua.
- XZ di chuyển bình thường. Kiểm tra khoảng cách XZ không bị ảnh hưởng bởi Y.
- Đây KHÔNG phải tuning field trong contract; ghi ở đây.

---

## 5. Tick execution order [ASSUME]

Trong mỗi bước k (tạo trạng thái k+1), theo đúng thứ tự:
1. Apply input frame cho tick k
2. Update player movement và jump
3. Collect eligible motes
4. Process lantern interaction
5. Process pulse
6. Process scheduled shade spawning
7. Update shade movement và stun states
8. Detect player hits và apply invulnerability
9. Update remaining time
10. Evaluate terminal conditions
11. Write events ngay khi sinh
12. Write periodic snapshot nếu đến lượt

Thứ tự terminal priority: `no_flames` > `all_lit` > `dawn`.
Nếu game over xảy ra ở tick snapshot, giữ cả event và snapshot; end record luôn viết cuối.

---

## 6. Scenario time override [REQ]

- `initial_time_left_s = scenario.time_left_s` nếu có, ngược lại `tuning.night1_duration_s`
- `time_left_s = max(0, initial_time_left_s − executed_ticks / 60.0)`

---

## 7. Điểm bonus khi thắng [ASSUME]

Khi `game_over result:"won"`:
- `score += per_second_left * floor(time_left_s) + per_flame_left * flames`
- Cộng một lần.

---

## 8. Bóng Mực [ASSUME]

- Di chuyển tới player trên XZ với `shade_speed/60` mỗi tick.
- Tôn trọng safe zone: không bao giờ vào trong `safe_radius` của đèn đã thắp. Nếu bước tiếp theo vào safe zone, shade trượt dọc biên tới điểm khả thi gần nhất (deterministic).
- Stunned shade không di chuyển.
- Trạng thái snapshot tối thiểu `stunned`; các tên khác (`chase`, …) tự đặt.

---

## 9. Entity IDs [ASSUME]

- ID từ scenario giữ nguyên.
- Shade tự sinh: `S1`, `S2`, … từ bộ đếm deterministic seeded bằng `--seed`.
- Mote tự sinh / dropped: `M1`, `M2`, … theo thứ tự khai báo/sinh.

---

## 10. Cài đặt / chạy [ASSUME]

- Headless không load scene 3D, không cần GPU.
- Shell script dùng `#!/usr/bin/env bash`, `GODOT_BIN` env override.
- `.gitattributes` ép LF.
