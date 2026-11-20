# TICKET-03 — "Đèn Cạn Dầu" (Phase 3)

Loại: Change request · Ưu tiên: Cao · Tag nộp: `phase-3` · Contract: v1.2

## Bối cảnh

Đêm 1–3 đã chạy được (Phase 2). Ticket này thay đổi mô hình đèn từ nhị phân (lit/unlit) sang mô hình có nhiên liệu, đổi điều kiện thắng từ "thắp hết đèn" sang "sống sót đến bình minh với đủ đèn sáng", thêm cơ chế Bóng Mực hút dầu, và tăng sức chứa theo số lần thắp thành công.

## 1. Contract v1.2

`contract_version: "1.2"`. Bổ sung tuning keys:

| Key | Giá trị |
|---|---|
| fuel_max | 100 |
| fuel_decay_per_s | 1.0 |
| fuel_per_mote | 10 |
| relight_cost | 5 |
| win_ratio | 0.6 |
| drain_per_s | 5 |
| low_fuel_threshold | 30 |
| capacity_max | 20 |
| night1_duration_s | 240 |
| night2_duration_s | 270 |
| night3_duration_s | 300 |

Config strict validate như v1.1. Int chấp nhận JSON integer-valued float.

## 2. Mô hình nhiên liệu đèn

Mỗi lantern có: `id, pos, lit, fuel, ever_lit, relit_count, deposited`.

Fuel tối đa 100. Khi thắp thành công lần đầu hoặc thắp lại: `fuel = 100`.

Đèn sáng tự hao `1.0/60` mỗi tick. Lưu nội bộ theo đơn vị 1/60: `fuel_units = fuel*60`, `full_fuel_units = 6000`. Mỗi tick đèn sáng mất 1 unit. Mỗi Shade drain đóng góp 5 unit/tick.

Khi `fuel <= 0`: `lit=false, fuel=0, deposited=0, ever_lit=true`; phát `lantern_out {lantern_id}`; cập nhật safe zone; shade đang drain đèn đó → wander. Không xóa `ever_lit` hoặc `relit_count`.

## 3. Thắp mới, thắp lại, châm dầu

- Đèn chưa từng sáng: cần 10 mote để thắp.
- Đèn đã từng sáng nhưng tắt: cần 5 mote để thắp lại.
- Châm dầu cho đèn đang sáng: `used = min(carried, ceil((100-fuel)/10))`; `fuel = min(100, fuel+10*used)`; trừ mote.
- Nếu full fuel: `used=0`, không chọn để tương tác, không event, không điểm.
- Chỉ xét đèn có thể nhận tài nguyên: tắt chưa từng sáng, tắt đã từng sáng, sáng nhưng fuel chưa đầy.
- Chọn gần nhất, tie-break ID tăng dần.
- +5 điểm mỗi mote nạp (thắp mới, thắp lại, refuel).
- Thắp lần đầu: +100, `ever_lit=true`, `successful_lights += 1`.
- Thắp lại: +40, `relit_count += 1`, `successful_lights += 1`.
- Refuel: +5 mỗi mote, không cộng điểm thắp.
- Scenario: lantern thêm `lit, fuel, ever_lit`; `lit=true` nhưng thiếu fuel → mặc định `fuel=100`; player thêm `successful_lights`; đèn đặt sẵn không tính successful lighting; setup không phát event, không cộng điểm.
- `deposited` phải nhất quán theo vòng đời; khi hết dầu về 0.

## 4. Shade hút dầu

- Đèn `fuel < 30` mất vùng an toàn (đúng 30 vẫn giữ).
- Chỉ Shade `wander` tìm đèn yếu: ưu tiên đèn sáng fuel<30 gần nhất, tie ID; không có thì đèn tắt gần nhất (luật cũ). Shade `chase` không tự đổi mục tiêu.
- Scenario shade thêm `target_lantern_id`.
- Shade cách đèn mục tiêu ≤2m XZ: chuyển `drain`, đứng yên, hút 5 fuel/s, nhiều shade cộng dồn.
- Thoát drain: player ≤6m → chase; pulse → stunned; đèn tắt → wander; fuel ≥30 → wander; >2m → wander; hết stunned → wander.
- Pulse: shade bình thường +5; shade đang drain +15 (tổng); stunned ưu tiên recoil.
- Đèn refuel từ <30 lên ≥30 và shade trong 6m: đẩy shade ra rìa safe zone ≤30 tick, không damage trong lúc push.
- Event `fuel_drain {lantern_id, shade_id, fuel}` mỗi 60 tick khi drain. `fuel` = lượng sau cập nhật. Nhiều shade drain cùng đèn → mỗi shade event riêng.
- Snapshot shade thêm state `drain`.

## 5. Điều kiện thắng/thua mới

Duration: N1=240s, N2=270s, N3=300s. Không còn thắng sớm khi tất cả đèn sáng.

`required_lit = ceil(0.6 * total_lanterns)`: N1=3/5, N2=4/6, N3=5/7.

Thắng: Mây còn sống khi hết giờ VÀ số lantern sáng tại tick cuối đạt ngưỡng → `dawn_survived`.
Thua: hết flames → `no_flames` lập tức; hết giờ không đạt ngưỡng → `dawn`.

Terminal order: `no_flames` > `dawn_survived` (nếu tick bình minh + đạt ngưỡng) > `dawn` (nếu tick bình minh + không đạt).

Trong tick bình minh: chạy đầy đủ tick order (trừ fuel, drain, tắt đèn cạn), sau đó xét terminal. `no_flames` luôn ưu tiên hơn. Không còn `all_lit`.

## 6. Capacity tăng dần

`capacity = min(20, 10 + 2 * successful_lights)`. `successful_lights` tăng mỗi lần thắp thành công (kể cả relight), không tính đèn đặt sẵn, reset mỗi Night. Snapshot player thêm `capacity`. HUD hiển thị `carried / capacity`.

## 7. Scoring v1.2

| Sự kiện | Điểm |
|---|---|
| Mỗi mote nạp | +5 |
| Thắp lần đầu | +100 |
| Thắp lại | +40 |
| Pulse shade bình thường | +5 |
| Pulse shade đang drain | +15 |
| Bình minh thắng: mỗi đèn sáng | +50 + floor(fuel) |
| Bình minh thắng: mỗi flame | +50 |

Không còn time bonus. Tổng điểm campaign = tổng điểm các Night thắng.

## 8. Snapshot/event v1.2

Lantern snapshot thêm: `fuel` (1 decimal, 0 khi tắt), `ever_lit`, `relit_count`. Player thêm `capacity`. Shade thêm state `drain`.

Event mới: `refuel {lantern_id, amount, fuel}`, `lantern_out {lantern_id}`, `fuel_drain {lantern_id, shade_id, fuel}`. `lantern_lit` thêm `"relight": true/false`. `game_over.reason` thêm `dawn_survived`, bỏ `all_lit`.

## 9. Colorblind mode

Setting lưu trên đĩa. Khi bật: viền/mắt Bóng Mực `#7A3CFF`→`#00B3FF`; UI warning `#FF5A5F`→`#FFFFFF` + icon `⚠`; đèn tắt xẹp 20%, giấy có vết rách; đèn fuel<30 nhấp nháy 1Hz; đèn sáng có fuel bar. Không dùng màu làm dấu hiệu duy nhất.

## 10. DoD

- Contract v1.2, ADR, Changelog breaking changes, evidence, tests green, Phase 1–2 hidden tests preserved where not superseded, tag `phase-3`.
