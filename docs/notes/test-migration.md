# Test migration — các luật/test bị thay thế

Quy ước: **S** = superseded (bị luật mới thay), **K** = kept (giữ nguyên, vẫn chạy). Không test nào bị `skip`.
Test bị thay không bị xóa âm thầm: assertion được cập nhật theo luật mới và liệt kê dưới đây.

## Phase 1 → Phase 2 (TICKET-02)

| Test | Luật cũ (v1.0) | Luật mới (v1.1) | Trạng thái | Lý do / test thay thế |
|---|---|---|---|---|
| F4 `carried` 3 | lantern_cost 3 | lantern_cost 10 | S (fixture) | Ngoại lệ fixture AGENTS.md: `f4.json` carried 3→10 |
| F7 `carried` 2 | pulse_cost 1→2 | pulse_cost 3 | S (fixture) | `f7.json` carried 2→3 |
| F19 jump | parabol 48 tick | `vel_y=7, g=-20` | S | F19 đo đỉnh > 1.0 m và hạ cánh Y<0.01 |
| F6 safe radius | 4 m | 6 m | K | kịch bản vẫn đúng (shade ở 5 m ngoài mép 4 m, nay bị chặn/đẩy) |
| F1–F3, F5, F8, F10–F16, F20, F21 | — | — | K | không đổi |

## Phase 2 → Phase 3 (TICKET-03 / contract v1.2)

| Test / luật | Luật cũ (v1.1) | Luật mới (v1.2) | Trạng thái | Test thay thế |
|---|---|---|---|---|
| F9 "win all_lit" | thắp đủ 5 đèn → thắng `all_lit` + time bonus | sống đến bình minh, ≥ ceil(0.6·N) đèn sáng → `dawn_survived` | **S** | F9 giờ assert `reason=dawn_survived`, `state=won` (time_left_s=1); unit `DAWN`, `EARLY`, `SCORE` |
| F11 dawn loss | hết giờ → `dawn` | hết giờ + dưới ngưỡng → `dawn` | K | vẫn đúng (0 đèn sáng) |
| Điểm `per_mote` | 10/mote | +5/mote nạp (mọi loại) | **S** | unit `LIGHT`, `REFUEL` |
| Điểm thắng | `floor(time_left)·2 + 50·flames` | `Σ(50+floor(fuel)) + 50·flames` | **S** | unit `SCORE` (xác nhận không còn time bonus) |
| Thời lượng đêm | 300 / 330 / 360 s | 240 / 270 / 300 s | **S** | unit `DAWN` (time_left_s) + F16/F20 không phụ thuộc |
| Ticks benchmark | 18000/19800/21600 | 14400/16200/18000 | **S** | `tests/perf_bench.py` dùng thời lượng v1.2 |
| Terminal `all_lit` | no_flames > all_lit > dawn | no_flames > dawn_survived > dawn | **S** | unit `NOFLAME`, `DAWN` |
| Capacity 10 cố định | `carry_capacity` | `min(20, 10+2·successful_lights)` | **S** | unit `CAP` ×4 |
| Đèn nhị phân | `lit`/`unlit` | + fuel/ever_lit/relit_count | **S** | unit `FUEL`, `ZERO`, `SNAP`, `EVT` |
| F12 no events at setup, F13, F14, F15 | — | — | K | không đổi |

## Phase 2 → Phase 4 (TICKET-04 / contract v1.3)

| Luật | Thay đổi | Trạng thái |
|---|---|---|
| Config `contract_version` | chấp nhận `1.1`/`1.2`/`1.3`; `1.3` bắt buộc `bench_cmd`, `soak_cmd` | thêm, không phá test cũ |
| Không luật gameplay nào bị Ticket-04 thay thế | — | toàn bộ test Phase 1–3 giữ nguyên |

## Sửa lỗi phát hiện khi audit (không phải thay luật)

| Lỗi | Sửa | Test |
|---|---|---|
| Rơi khỏi đảo trừ 2 Ngọn Lửa (lúc rơi + lúc hồi sinh) | chỉ trừ lúc rơi (TICKET-02 "đúng 1 lần") | unit `FALL` |
| Bộ đếm choáng/recoil giảm ở bước 8 | bước 2 (đúng thứ tự TICKET-02) | unit `STUN` |
| Safe push khi đèn vừa sáng chưa có | thêm `_trigger_safe_push` | unit `PUSH`, `NODMG` |
| `headless.gd` trả `null` cho `Dictionary` → arg sai không thoát lỗi | trả `{"__error":true}` | run_tests `N-bad` |
| `game_over` có thể ghi 2 lần (rơi + hết giờ) | `_check_terminal` idempotent | unit `NOFLAME` |
