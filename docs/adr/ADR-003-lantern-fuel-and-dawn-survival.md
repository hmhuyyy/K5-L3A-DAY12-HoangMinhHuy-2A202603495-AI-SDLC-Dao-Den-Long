# ADR-003 — Đèn cạn dầu và sống sót đến bình minh (Contract v1.2)

- Trạng thái: Chấp nhận · Phase 3 · Thay thế một phần luật Phase 2 (xem §Tương thích)
- Nguồn: `docs/spec/TICKET-03.md`, `game.contract.json` v1.2

## 1. Bối cảnh

Phase 2 dùng đèn nhị phân (`lit`/`unlit`), thắng sớm khi thắp đủ đèn (`all_lit`), điểm thưởng thời gian
`floor(time_left_s) × 2`. TICKET-03 đổi cốt lõi: đèn có nhiên liệu, Bóng Mực hút dầu, thắng khi sống đến bình
minh với ≥ 60 % đèn sáng, sức chứa tăng theo số lần thắp.
Luật cũ bị thay thế đã bị **xóa** khỏi `GameSim` (không còn nhánh `all_lit`, không còn time bonus), không giữ song song.

## 2. Mô hình trạng thái đèn

`LanternData { id, pos, lit, fuel_units, ever_lit, relit_count, deposited }`.

| Trạng thái | Điều kiện | Nhận tài nguyên |
|---|---|---|
| chưa từng sáng | `!lit && !ever_lit` | 10 mote (`lantern_cost`) → thắp lần đầu |
| tắt đã từng sáng | `!lit && ever_lit` | 5 mote (`relight_cost`) → thắp lại |
| sáng, chưa đầy | `lit && fuel < 100` | châm dầu |
| sáng, đầy | `lit && fuel == 100` | **không** (không chọn, không event, không điểm) |

## 3. Biểu diễn nhiên liệu

Số nguyên **fuel_units = fuel × 60** (đầy = 6000). Mỗi tick đèn sáng mất `roundi(fuel_decay_per_s)` = 1 unit;
mỗi Shade `drain` trừ thêm `roundi(drain_per_s)` = 5 unit/tick (= 5 fuel/giây). Không có số float cộng dồn nên
đèn đầy cháy hết đúng 6000 tick (kiểm tra bằng test). Chuyển sang float chỉ khi ghi snapshot/event, làm tròn 1 chữ số.
Châm dầu dùng số học nguyên: `used = min(carried, ceil((6000 − units) / 600))`.

Hết dầu (`units ≤ 0`): `lit=false, fuel=0, deposited=0, ever_lit=true`, phát `lantern_out`, vùng an toàn biến mất
ngay (vùng an toàn được suy ra từ trạng thái đèn mỗi lần truy vấn), Shade đang drain đèn đó → `wander` ngay trong tick.
`ever_lit` và `relit_count` không bao giờ bị xóa.

### Ngữ nghĩa `deposited` (quyết định)
`deposited` = số mote đã nạp cho **lần thắp đang dở** (đèn tắt). Về 0 khi: thắp thành công, hoặc hết dầu.
Đèn đang sáng luôn có `deposited = 0`; refuel không dùng `deposited`. Scenario có thể đặt `deposited` tùy ý.

## 4. Thắp, thắp lại, châm dầu, chọn đèn

- Ứng viên: mọi đèn *không* ở trạng thái "sáng, đầy". Chọn gần nhất trong `interact_radius` (XZ), hòa → id tăng dần.
- +5/mote nạp (mọi loại). Thắp lần đầu +100 (`successful_lights += 1`), thắp lại +40 (`relit_count += 1`,
  `successful_lights += 1`), refuel không có thưởng thắp.
- Bước 2 (giảm bộ đếm) chạy **trước** bước 5 (tương tác) trong cùng tick, nên đèn "100.0" ở đầu tick đã là 99.98 khi
  nhấn E — refuel 1 mote vẫn hợp lệ. Đèn đã đầy hoàn toàn (6000 units) mới bị loại.

## 5. Shade hút dầu

- Vùng an toàn chỉ tồn tại khi `lit && fuel ≥ 30` (đúng 30 vẫn giữ; `< 30` mất).
- Trạng thái `drain`. Shade `wander` (và chỉ `wander`) chọn mục tiêu: đèn **sáng** `fuel < 30` gần nhất (tính từ
  vị trí **Shade**), hòa → id; nếu không có thì đèn **tắt** gần nhất ("luật cũ" của ticket) và đi tới, đứng yên khi
  ≤ 2 m (đèn tắt không có gì để hút nên không vào `drain`). Mục tiêu hợp lệ sẵn có (từ scenario) được giữ, trừ khi
  xuất hiện đèn yếu thì đèn yếu thắng đèn tắt.
- Shade `chase` không đổi `target_lantern_id`.
- ≤ 2 m XZ tới đèn sáng-yếu → `drain`, đứng yên, hút cộng dồn theo số Shade.
- Thoát `drain` (kiểm tra theo thứ tự): player ≤ 6 m (`safe_radius`, không thêm key mới để không phá contract) → `chase`;
  pulse → `stunned` (bước 7, trước bước 8); đèn tắt → `wander`; fuel ≥ 30 → `wander`; > 2 m → `wander`;
  hết `stunned` → `wander`.
- Pulse: shade thường +5, shade đang `drain` ngay trước pulse +15 (tổng, không +20). `previous_state` chỉ được ghi từ
  `wander/chase` (drain/spawning quy về `wander`); `recoil/stunned` giữ giá trị cũ ⇒ pulse lại một Shade đang choáng
  chỉ +5 và `stunned` ưu tiên `recoil`.
- `fuel_drain`: mỗi 60 tick *drain thực sự* của từng Shade (bộ đếm `drain_ticks`), `fuel` = giá trị sau cập nhật tick,
  mỗi Shade một event riêng.
- **Safe push** (Phase 2 yêu cầu nhưng chưa có; hoàn thiện ở Phase 3): khi đèn *vừa trở thành* vùng an toàn — thắp,
  thắp lại, hoặc refuel từ `< 30` lên `≥ 30` — Shade trong 6 m được đẩy tuyến tính tới `safe_radius + 0.01` trong
  `safe_push_ticks` (30) tick, không gây sát thương, ghi đè chuyển động AI.

## 6. Bình minh

`required_lit = ceil(win_ratio × tổng_đèn − 1e-9)` (epsilon chống nhiễu float `0.6×5`): N1 3/5, N2 4/6, N3 5/7.
Tick bình minh chạy đầy đủ 12 bước (trừ dầu, drain, tắt đèn cạn) rồi mới xét terminal:
`no_flames` > `dawn_survived` > `dawn`. Không còn `all_lit`. `_check_terminal` idempotent (đúng 1 `game_over`).
Thắng: mỗi đèn sáng `+50 + floor(fuel)`, mỗi flame `+50`. Thua: không thưởng cuối.

## 7. Điểm v1.2 và Capacity

Contract `tuning.score`: `per_mote 5, per_lantern 100, per_relight 40, per_stun 5, per_stun_drain 15,
per_lantern_at_dawn 50, per_flame_left 50`. Không còn `per_second_left`/time bonus.
`capacity = min(capacity_max, 10 + 2 × successful_lights)`; scenario đặt sẵn đèn **không** tăng;
`player.successful_lights` trong scenario cho phép dựng tình huống; reset mỗi Night (sim mới).

## 8. Tương thích ngược / thay đổi phá vỡ

Breaking so với v1.1: xem `CHANGELOG.md`. Snapshot/Event chỉ **thêm** trường (`fuel`, `ever_lit`, `relit_count`,
`capacity`, state `drain`, event `refuel/lantern_out/fuel_drain`, `lantern_lit.relight`, `game_over.reason=dawn_survived`);
bị bỏ: reason `all_lit`, thưởng thời gian, thời lượng đêm 300/330/360 → 240/270/300.
`Config` chấp nhận contract `1.1`–`1.3` nhưng chỉ `1.2+` có đủ key fuel; thiếu key ⇒ lỗi rõ tên field.

## 9. Quyết định bổ sung cho phần ticket chưa quy định

| # | Quyết định | Lý do |
|---|---|---|
| D-3.1 | Bộ đếm choáng/recoil giảm ở **bước 2** (trước đây ở bước 8) | Khớp thứ tự 12 bước TICKET-02; choáng kéo dài đúng 120 tick |
| D-3.2 | Rơi khỏi đảo trừ **đúng 1** Ngọn Lửa (trước đây trừ thêm lần nữa lúc hồi sinh) | TICKET-02: "xảy ra đúng 1 lần"; lỗi Phase 2 phát hiện khi audit |
| D-3.3 | Ngưỡng "player ≤ 6 m → chase" dùng `safe_radius` | Tránh thêm key contract (bộ test ẩn có thể thay contract) |
| D-3.4 | Shade đi tới đèn tắt gần nhất khi không có đèn yếu | Đọc đúng "như luật cũ" của ticket; đèn tắt không bị drain |
| D-3.5 | Push dùng đích `safe_radius + 0.01` | Bảo đảm nằm *ngoài* vùng (`≤ safe_radius` là trong) |
| D-3.6 | `_check_terminal` idempotent, tick sau terminal là no-op | Tránh `game_over` trùng khi rơi + hết giờ cùng tick |

## 10. Hậu quả

- Mọi hằng số nằm trong contract; test đơn vị đọc cùng `Config`.
- Phase 1–2 test không bị thay thế vẫn chạy; danh sách bị thay thế ở `docs/notes/test-migration.md`.
