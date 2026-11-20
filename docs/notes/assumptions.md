# Assumptions — Đảo Đèn Lồng

> Quy ước: **[REQ]** = nguyên văn TICKET/PRD; **[ASSUME-APPROVED]** = giả định được duyệt; **[OPEN]** = chưa xác nhận.
> Mọi số tuning chỉ nằm trong `game.contract.json`. Cập nhật lần cuối: Phase 2 Giai đoạn 0.

---

## ── PHASE 1 (giữ nguyên, số cũ bị thay bởi Phase 2) ──

> **Lưu ý:** Toàn bộ số liệu §1–§10 (Phase 1) đã bị thay thế bởi số chuẩn TICKET-02.
> Test ẩn Phase 1 sẽ dùng số chuẩn mới. Phần §1–§10 bên dưới chỉ giữ lại
> để ghi lịch sử và lý do thay đổi.

### 1-P1. Tuning Phase 1 (ĐÃ BỊ THAY — xem §P2 bên dưới)

| Trường | v1.0 | v1.1 | Lý do |
|---|---|---|---|
| player_speed | 5.0 | **6.0** | REQ TICKET-02 |
| carry_capacity | 5 | **10** | REQ TICKET-02 |
| lantern_cost | 3 | **10** | REQ TICKET-02 |
| pickup_radius | 1.5 | **1.0** | REQ TICKET-02 |
| interact_radius | 2.5 | **2.0** | REQ TICKET-02 |
| pulse_cost | 1 | **3** | REQ TICKET-02 |
| pulse_stun_s | 3 s (180 tick) | **120 tick** | REQ TICKET-02 |
| pulse_cooldown_s | 5 s | **3 s** | REQ TICKET-02 |
| safe_radius | 4 m | **6 m** | REQ TICKET-02 |
| shade_speed | 3.0 | **4.0** | REQ TICKET-02 |
| shade_hit_radius | 1.0 m | **1.0 m + chênh cao 1.5 m** | REQ TICKET-02 |
| fall_enabled | false | **true** | REQ TICKET-02 |
| score.per_mote | 10 (khi nhặt) | **10 khi NẠP** | REQ TICKET-02 |
| score.per_stun | 20 | **5** | REQ TICKET-02 |
| score.per_second_left | 5×s | **floor(s)×2** | REQ TICKET-02 |
| invuln | 1.5 s | **90 tick** (nhất quán) | REQ TICKET-02 |

### 2-P1. Mote Phase 1 (ĐÃ THAY)

Phase 1 dùng 25 mote ngẫu nhiên, không TTL, không spawn schedule.
Phase 2 dùng 20 mote ban đầu tại vị trí cố định, TTL 480 tick cho dropped, spawn +1 mỗi 240 tick.

### 3-P1. Jump Phase 1 (ĐÃ THAY)

Phase 1 dùng parabol cố định 48 tick, peak 1.5 m.
Phase 2 dùng vật lý vận tốc: vel_y=7.0, gravity=−20 m/s² (đỉnh 1.225 m, bay ≈42 tick).
Test F19 phải viết lại theo số mới.

### 4-P1. Tick order Phase 1 (ĐÃ THAY)

Phase 2 dùng thứ tự 12 bước của TICKET-02 (xem §P2.4).

### 5-P1. Điểm thắng Phase 1 (ĐÃ THAY)

Phase 1: `+floor(time)×5 + 50×flames`.
Phase 2: `+floor(time)×2 + 50×flames`. **[REQ TICKET-02]**

---

## ── PHASE 2 ──

### P2.1. World angle convention [REQ]

- **[REQ TICKET-02 L103]** "Góc đo từ trục +X, ngược chiều kim đồng hồ khi nhìn từ trên xuống, trên mặt phẳng XZ."
- **Chứng minh 90°=+Z:** tầng 1 Đêm 3 "bán kính 12–24 m ở nửa có z>0", điểm tầng 1 tại 20°–160° → phải là z>0 → z=r·sin(a).
- Công thức: `x = r·cos(a), z = r·sin(a)`, góc 0°=+X, 90°=+Z.
- **Camera yaw (PRD-0)** dùng công thức riêng; **không dùng chung helper** với world angle.
- `wind.dir_deg` dùng quy ước world angle.

### P2.2. Mote ban đầu và spawn points

**[REQ]** 20 motes ban đầu tại 20 điểm, trần 30, spawn +1 mỗi 240 tick tại điểm trống.

**[REQ]** Điểm sinh Đêm 1: 8 điểm r=12 m (mỗi 45°) + 16 điểm r=33 m (mỗi 22.5°) = 24 điểm.

**[ASSUME-APPROVED C4]** 20 initial motes = In01–In08 (vòng trong) + Out01–Out12 (vòng ngoài 0°→247.5°). Out13–Out16 (270°–337.5°) trống, dùng cho spawn schedule.

Tọa độ đầy đủ 24 điểm (tính x=r·cos(a), z=r·sin(a)):

**Vòng trong r=12 (8 điểm):** (12,0,0) · (8.485,0,8.485) · (0,0,12) · (-8.485,0,8.485) · (-12,0,0) · (-8.485,0,-8.485) · (0,0,-12) · (8.485,0,-8.485)

**Vòng ngoài r=33 (16 điểm):** 0°(33,0,0) · 22.5°(30.488,0,12.629) · 45°(23.335,0,23.335) · 67.5°(12.629,0,30.488) · 90°(0,0,33) · 112.5°(-12.629,0,30.488) · 135°(-23.335,0,23.335) · 157.5°(-30.488,0,12.629) · 180°(-33,0,0) · 202.5°(-30.488,0,-12.629) · 225°(-23.335,0,-23.335) · **247.5°(-12.629,0,-30.488)** [dừng ở đây] · 270°(0,0,-33)[trống] · 292.5°(12.629,0,-30.488)[trống] · 315°(23.335,0,-23.335)[trống] · 337.5°(30.488,0,-12.629)[trống]

**Spawn schedule:** tại tick 240, 480, … → chọn điểm trống đầu tiên theo thứ tự góc tăng; hết → bỏ lượt.

**Điểm sinh đom đóm Đêm 2:** mỗi đảo: 4 điểm r=10 (0°,90°,180°,270°) + 8 điểm r=22 (mỗi 45°) = 12 điểm/đảo, 24 tổng. **[REQ]**

**Điểm sinh đom đóm Đêm 3:** 30 điểm: tầng 0 (18 điểm r=34, mỗi 20° từ 0°) + tầng 1 (8 điểm r=18, 20°–160°) + tầng 2 (4 điểm r=5, 45°/135°/225°/315°). **[REQ]**

### P2.3. Vật lý nhảy / dash / bounce [REQ + ASSUME]

**[REQ TICKET-02]** `vel_y = 7.0` lúc nhảy, `gravity = -20.0 m/s²`, chỉ nhảy khi grounded.

**[ASSUME-APPROVED B5]** Tích phân semi-implicit Euler, dt=1/60:
```
1. Jump/dash/bounce: đặt vel
2. Gia tốc (ground accel ≤ 0.1s = 60 m/s² [B5]): áp dụng mọi lúc (C1 full air control)
3. Gravity: vel.y += gravity * dt = vel.y - 1/3 mỗi tick
4. Vị trí: pos += vel * dt
5. Ground: nếu pos.y <= ground_y(x,z) và vel.y <= 0 → snap, grounded=true, vel.y=0
6. Fall: pos.y < -10 → trigger fall
```

Đỉnh nhảy: v²/(2g) = 49/40 = **1.225 m**. Thời gian bay ≈ 2×7/20 = **0.7 s = 42 tick**.

**[DECIDE C1]** Air control đầy đủ: cùng gia tốc/dừng như trên đất; tốc độ ngang tối đa 6 m/s.

**[REQ]** Dash 14 m/s / 0.2 s (12 tick) / cooldown 1.5 s; giữ độ cao (vel.y không đổi); không bất tử.

**[REQ]** Bounce pad (Đêm 2): vel_y=14, ngang=24 m/s hướng tâm đảo kia; giữ tới grounded; phím move không ghi đè; dash vẫn ghi đè.

**[REQ]** Bounce pad (Đêm 3, (0,3,13)): vel_y=12, ngang=8 m/s hướng −Z.

**[ASSUME-APPROVED B6]** Điều kiện bounce: dist XZ ≤ 1 m, `swept contact` với `pad_top_y`, vel.y ≤ 0, chống trigger lặp bằng cờ re-arm khi dist XZ > 1.5 m. Dung sai 0.5 m trên Y là giả định.

**[ASSUME-APPROVED B7]** Gió tác dụng cả khi airborne.

### P2.4. Thứ tự tick Phase 2 [REQ]

Thứ tự bắt buộc (TICKET-02 §"Thứ tự xử lý"):

```
1. Đọc input (xử lý pause trước; nếu vừa tạm dừng → dừng ngay bước này)
2. Giảm bộ đếm: sim_time, cooldowns, invuln, stun, charm, TTL dropped motes, charm respawn
3. Di chuyển Mây (jump, dash, bounce, wind) + kiểm tra rơi
4. Nhặt đom đóm và bùa
5. Tương tác đèn
6. Cập nhật vùng an toàn
7. Tỏa Sáng
8. Di chuyển Bóng Mực và Gió Lạc
9. Chạm: Gió Lạc cướp trước → Bóng Mực (theo id tăng dần)
10. Sinh đom đóm / Bóng Mực / Gió Lạc (thực thể mới chỉ tương tác từ tick sau)
11. Xét thắng/thua
12. Ghi snapshot nếu đến lượt
```

Terminal priority: `no_flames` > `all_lit` > `dawn`. **[REQ]**

Khi pause (bước 1 dừng): `executed_ticks` tăng, `sim_tick` đứng yên, bộ đếm bước 2 không giảm, spawn bước 10 không chạy, snapshot ghi `state:"paused"`. **[REQ TICKET-02 L97]**

### P2.5. Tick semantics khi pause [REQ + ASSUME]

**[REQ]** `executed_ticks` tăng khi pause. `sim_tick` đứng yên.

**[ASSUME-APPROVED D2]** `snapshot.tick = executed_ticks`; `snapshot.sim_tick = sim_tick`. Cadence snapshot theo `executed_ticks`.

**[ASSUME-APPROVED B3/B4]** Resume tick chạy full logic bước 2–12 + ghi `resumed` event. Input frame tick ánh xạ `executed_ticks` (input đọc ngay cả khi pause để bắt rising edge resume).

**[DECIDE C3]** `end.state = "playing"` khi hết `--ticks` trong lúc paused.

Phân biệt off-by-one: bước k → `current_tick = executed_ticks + 1`; sau bước k `executed_ticks += 1`; nếu logic chạy đầy đủ `sim_tick += 1`.

### P2.6. Shade state machine [REQ + ASSUME]

**[REQ TICKET-02 §Contract v1.1]** 5 trạng thái: `spawning`, `wander`, `chase`, `recoil`, `stunned`.

**[REQ]** Phát hiện 12 m / bỏ đuổi 18 m. Lịch sinh Đêm 1: 2 con tick 300, rồi 1 mỗi (300+480k). Max 6.

**[ASSUME-APPROVED B10]** Đêm 2/3 cũng 2 con tại tick 300, rồi 1 mỗi 7s (420 tick) / 6s (360 tick). Max 8/10.

**[ASSUME-APPROVED B12]** Wander = đứng yên (TICKET không cho tốc độ wander).

**[ASSUME-APPROVED B13]** State transitions với hysteresis và previous_state:
- `spawning` (1 tick) → `wander`
- `wander` ↔ `chase`: transitions bình thường không lưu previous_state:
  - `wander` → `chase` khi dist ≤ detect_m (12 m)
  - `chase` → `wander` khi dist > abandon_m (18 m)
- `chase` → `recoil` khi gây hit: **lưu previous_state = "chase"** (trạng thái tạm thời)
- Thoát `recoil` (60 tick): **phục hồi hysteresis từ previous_state**:
  - previous = "chase" → tiếp tục chase cho đến khi dist > 18 m
  - previous = "wander" → tiếp tục wander cho đến khi dist ≤ 12 m
- Bất kỳ → `stunned` khi pulse trúng: **lưu previous_state** (trạng thái tạm thời); `stunned` ưu tiên hơn `recoil`
- Thoát `stunned` (120 tick): giống thoát `recoil` — **phục hồi hysteresis từ previous_state**
- Lưu ý: transitions bình thường `wander` ↔ `chase` không cần lưu previous_state; chỉ trạng thái tạm thời (`recoil`, `stunned`) lưu để khôi phục

**[REQ]** Recoil: Shade lùi 2 m trong 60 tick (không phải player). **[ASSUME-APPROVED B16]** Hướng = ra xa player.

**[REQ]** Vùng an toàn 6 m: shade ngoài bị chặn ở mép. Shade trong khi đèn vừa sáng → đẩy ra mép ≤ 30 tick, không gây sát thương trong lúc đó. **[REQ TICKET-02]**

### P2.7. Drifter state machine [REQ + ASSUME]

**[REQ]** 4 trạng thái: `idle`, `chase`, `flee`, `removed`. Sinh tại tick 1200, 2400, … Max 2 con.

**[ASSUME-APPROVED B11]** Drifter đạt cap → skip lượt spawn (không xếp hàng).

**[ASSUME-APPROVED B14]** Idle: heading xoay 0.5°/tick, speed 2 m/s → quỹ đạo **đường tròn bán kính 3.82 m**, tâm lệch khỏi điểm sinh theo phương vuông góc heading ban đầu. Không xử lý biên đảo (bay tự do). Góc 0.5°/tick là giả định, không phải tuning.

**[OPEN B15]** Điểm sinh Drifter = "điểm sương ngẫu nhiên". TICKET không định nghĩa tập này. `WorldDefs` phải định nghĩa `mist_spawn_points` **độc lập** với mote spawn points. Chờ định nghĩa.

**[REQ]** Pulse trúng chase → flee (không cướp). Pulse trúng flee có đồ → thả motes tại chỗ, removed sau 120 tick.

### P2.8. Gió (Wind) [REQ + ASSUME]

**[REQ TICKET-02 L147]** Mỗi 30 s (1800 tick): 5 s active (300 tick), báo trước 2 s.

**[ASSUME-APPROVED C5/B8]** Warning tại tick 1680, active tại tick 1800; chu kỳ tiếp: warning 3480, active 3600. Không có gió trong 28 s đầu.

**[DECIDE C2]** `wind.dir_deg` là số. Giai đoạn gió xác định bằng `sim_tick`, không dùng dir_deg=0 làm sentinel. Calm: `active=false`, dir_deg = giá trị bất kỳ (không có ý nghĩa semantic); phase được suy từ sim_tick.

**[ASSUME-APPROVED B7]** Gió tác dụng khi airborne.

### P2.9. Điểm Phase 2 [REQ]

**[REQ TICKET-02 L67]**
- +10 mỗi đom đóm **NẠP** (deposit), không phải nhặt.
- +100 mỗi đèn thắp.
- +5 mỗi Bóng Mực trúng Tỏa Sáng (mỗi con mỗi lần, kể cả con đang choáng).
- Khi thắng: `+floor(time_left_s) × 2 + 50 × flames`.
- Tổng điểm game = tổng điểm các đêm đã thắng.

**Contract v1.1 canon:** `tuning.score.per_mote = 10`. **Config.gd canon:** `score_per_mote` (property).

**Lưu ý Phase 1→2:** GameSim Phase 1 hiện tại cộng `score_per_mote` khi **PICKUP** event, không phải khi DEPOSIT. Alias compat `score_per_mote` bảo đảm Config load đúng; **semantics thực hiện DEPOSIT** sẽ chuyển đổi khi GameSim được viết lại (Giai đoạn 2).

### P2.10. Multi-night và Campaign [REQ + ASSUME]

**[REQ]** `--night` nhận 1, 2, 3 — mỗi run headless chạy **1 đêm đơn lẻ**.

**[ASSUME]** CampaignController chỉ tồn tại trong 3D/gameplay; lưu `campaign_score`, `current_night`, `nights_won`. Headless không có trạng thái campaign.

### P2.11. Entity IDs Phase 2

**[REQ]** Shade: S1, S2, … theo thứ tự sinh. **[REQ]** Drifter: D1, D2, … **[REQ]** Charm: C1, C2.

**[ASSUME]** Mote dropped: ID tiếp nối bộ đếm M hiện tại.

### P2.12. Benchmark performance [REQ + DECIDE]

**[REQ TICKET-02 §Contract v1.1]** Full night ≤ 30 s.

Tick tối đa per night: Đêm 1 = 18.000, Đêm 2 = 19.800, Đêm 3 = 21.600 (= 360×60).

**[DECIDE C6]** Tất cả 3 lần đo đều phải ≤ 30 s. Báo min/median/max. Dùng `time.perf_counter()` Python portable.

**[DECIDE C2]** (sửa từ DECIDE thành duyệt rồi) `wind.dir_deg` là số. Giai đoạn gió xác định bằng `sim_tick`, không dùng dir_deg=0 làm sentinel.

**[ASSUME-APPROVED B7]** Gió tác dụng khi airborne.

### P2.9. Điểm Phase 2 [REQ]

**[REQ TICKET-02 L67]**
- +10 mỗi đom đóm **NẠP** (deposit), không phải nhặt.
- +100 mỗi đèn thắp.
- +5 mỗi Bóng Mực trúng Tỏa Sáng (mỗi con mỗi lần, kể cả con đang choáng).
- Khi thắng: `+floor(time_left_s) × 2 + 50 × flames`.
- Tổng điểm game = tổng điểm các đêm đã thắng.

**LƯU Ý:** GameSim Phase 1 hiện tại vẫn **cộng điểm khi PICKUP** (semantics cũ: `cfg.score_per_mote` ghi khi `mote_picked`), không phải khi DEPOSIT. Alias compat `score_per_mote` chỉ bảo đảm thuộc tính được đọc đúng; **chưa thực hiện semantics deposit mới**. Chỉ tuyên bố semantics hoàn thành sau khi GameSim được viết lại (Giai đoạn 2).

---

## ── DECIDE (quyết định đã được duyệt) ──

| ID | Quyết định |
|---|---|
| **C1** | Full air control; cùng gia tốc/dừng như trên đất; tốc độ ngang tối đa 6 m/s |
| **C2** | wind.dir_deg là số; phase gió suy từ sim_tick, không dùng dir_deg=0 |
| **C3** | Hết ticks khi paused: end.state = "playing" |
| **C5** | Warning tick 1680, active tick 1800; chu kỳ 1800 |
| **C6** | Benchmark: 3 lần, tất cả ≤ 30 s, báo min/median/max |

---

## ── OPEN ITEMS (chưa xác nhận) ──

| ID | Vấn đề | Tác động |
|---|---|---|
| **OPEN-B15** | Tập điểm sương cho drifter spawn chưa định nghĩa; WorldDefs phải cung cấp `mist_spawn_points` riêng | Vị trí drifter lúc sinh deterministic |
