# EVIDENCE.md — Phase 3 Verification ("Đèn Cạn Dầu")

> Repo: `hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long`
> Branch / Tag: `phase-3`
> Contract: `v1.2` (`docs/spec/TICKET-03.md`)
> ADR: `docs/adr/ADR-003-lantern-fuel-and-dawn-survival.md`
> Test suite: `bash tests/run_tests.sh` → **279 passed, 0 failed** (bao gồm 34 scenario/headless tests, 173 unit assertions Phase 3, 53 unit/UI assertions Phase 3–4)

---

## 1. Requirement → Evidence Matrix (TICKET-03)

| # | Yêu cầu TICKET-03 | Nguồn | Test / Kịch bản xác minh | Kết quả |
|---|---|---|---|---|
| 1 | Contract v1.2 & Strict Config Validation (int nhận integer-valued float, từ chối fractional/bool/string/null/NaN/Inf, báo field path) | §1 | `run_unit.gd::t_config_strict` (19 assertions) | ✅ PASS |
| 2 | Mô hình nhiên liệu整数 `fuel_units = fuel * 60` (`full = 6000`), tự hao `1 unit/tick` (`1.0/60`), cháy hết đúng 6000 tick không sai số float | §2 | `run_unit.gd::t_fuel_decay`, `H1` (`tests/scenarios/h1_fuel.json`) | ✅ PASS |
| 3 | Khi `fuel <= 0`: `lit=false, fuel=0, deposited=0, ever_lit=true`, giữ `relit_count`, phát `lantern_out {lantern_id}` đúng 1 lần, mất safe zone ngay, Shade đang drain → `wander` | §2 | `run_unit.gd::t_fuel_zero`, `H3` (`tests/scenarios/h3_drain.json`) | ✅ PASS |
| 4 | Thắp mới (10 mote): `fuel=100`, `+5/mote`, `+100` lần đầu, `ever_lit=true`, `successful_lights += 1`, `lantern_lit {relight: false}` | §3 | `run_unit.gd::t_first_light`, `F4` | ✅ PASS |
| 5 | Thắp lại (5 mote): `fuel=100`, `+5/mote`, `+40` thắp lại, `relit_count += 1`, `successful_lights += 1`, `lantern_lit {relight: true}` | §3 | `run_unit.gd::t_relight`, `H2` (`tests/scenarios/h2_relight.json`) | ✅ PASS |
| 6 | Châm dầu: `used = min(carried, ceil((100-fuel)/10))`, `fuel = min(100, fuel+10*used)`, `+5/mote`, không thưởng thắp, phát `refuel {lantern_id, amount, fuel}` | §3 | `run_unit.gd::t_refuel_ceil` | ✅ PASS |
| 7 | Đèn đầy dầu (`fuel=100`): `used=0`, không được chọn để tương tác, không phát event, không cộng điểm | §3 | `run_unit.gd::t_refuel_full_noop` | ✅ PASS |
| 8 | Chọn đèn: chỉ xét đèn nhận tài nguyên (tắt chưa sáng, tắt từng sáng, sáng chưa đầy); chọn gần nhất trong `interact_radius`, hòa → ID tăng dần | §3 | `run_unit.gd::t_lantern_selection` | ✅ PASS |
| 9 | Safe zone: `fuel >= 30` giữ vùng an toàn (đúng 30 vẫn giữ); `fuel < 30` mất vùng an toàn | §4 | `run_unit.gd::t_safe_zone_threshold`, `F6` | ✅ PASS |
| 10 | Shade `wander` tìm đèn yếu: ưu tiên đèn sáng `fuel < 30` gần nhất (hòa → ID); không có thì đèn tắt gần nhất; Shade `chase` không đổi mục tiêu | §4 | `run_unit.gd::t_wander_weak_target` | ✅ PASS |
| 11 | Shade `drain`: cách đèn mục tiêu `<= 2m` XZ → `drain`, đứng yên, hút `5 fuel/s` (`5 units/tick`), nhiều Shade cộng dồn; ghi `fuel_drain {lantern_id, shade_id, fuel}` mỗi 60 ticks riêng từng Shade | §4 | `run_unit.gd::t_drain_basic`, `t_drain_stacking`, `H3` | ✅ PASS |
| 12 | Thoát `drain` đủ 6 điều kiện: player `<= 6m` → `chase`; pulse → `stunned`; đèn tắt → `wander`; fuel `>= 30` → `wander`; cách `> 2m` → `wander`; hết `stunned` → `wander` | §4 | `run_unit.gd::t_drain_exits` | ✅ PASS |
| 13 | Pulse trúng Shade: bình thường `+5`; đang `drain` ngay trước pulse tổng `+15` (không phải +20); `stunned` ưu tiên hơn `recoil` | §4 | `run_unit.gd::t_pulse_normal`, `t_pulse_drain` | ✅ PASS |
| 14 | Safe push: đèn vừa thành vùng an toàn (thắp mới / thắp lại / refuel từ `<30` lên `>=30`) đẩy Shade trong 6m ra rìa trong `<= 30 ticks`, không gây sát thương khi push | §4 | `run_unit.gd::t_safe_push`, `t_safe_push_no_damage` | ✅ PASS |
| 15 | Bình minh (`dawn_survived` vs `dawn` vs `no_flames`): N1=240s (3/5), N2=270s (4/6), N3=300s (5/7); không thắng sớm `all_lit`; tick bình minh chạy đủ tick order trước khi xét terminal; `no_flames` ưu tiên cao nhất | §5 | `run_unit.gd::t_dawn_thresholds`, `t_no_early_win`, `t_no_flames_at_dawn`, `F9`, `F11` | ✅ PASS |
| 16 | Capacity tăng dần: `capacity = min(20, 10 + 2 * successful_lights)` (cả first light và relight, không tính đèn đặt sẵn bởi scenario, reset mỗi Night, HUD hiển thị `carried / capacity`) | §6 | `run_unit.gd::t_capacity_light`, `t_capacity_relight`, `t_capacity_prelit`, `t_capacity_cap`, `run_unit_p4.gd` | ✅ PASS |
| 17 | Scoring v1.2: `+5/mote`, `+100` first light, `+40` relight, `+5` pulse thường, `+15` pulse drain, thắng bình minh `+50 + floor(fuel)` mỗi đèn sáng + `+50 * flames`, bỏ time bonus | §7 | `run_unit.gd::t_dawn_score` | ✅ PASS |
| 18 | Snapshot & Event v1.2: lantern `{fuel, ever_lit, relit_count}`, player `{capacity}`, shade state `drain`, events `refuel`, `lantern_out`, `fuel_drain`, `lantern_lit.relight`, `game_over.reason=dawn_survived` | §8 | `run_unit.gd::t_snapshot_v12`, `t_events_v12`, `H3` | ✅ PASS |
| 19 | Colorblind mode ("Bảng màu dễ phân biệt") lưu trên đĩa: Shade `#7A3CFF` → `#00B3FF`, UI warning `#FF5A5F` → `#FFFFFF` + `⚠`, đèn tắt xẹp 20% + vết rách, đèn `fuel < 30` nhấp nháy 1 Hz, đèn sáng có fuel bar | §9 | `run_unit_p4.gd::t_gamescene_3d_colorblind_and_hud` | ✅ PASS |
| 20 | Determinism cùng seed (Night 1, 2, 3 byte-identical JSONL) | §10 | `F2`, `N1`, `N2`, `N3`, `run_unit.gd::t_determinism` | ✅ PASS |

---

## 2. Cách tái hiện kiểm thử

```bash
bash tests/run_tests.sh
```
