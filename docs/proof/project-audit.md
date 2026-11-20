# Project Audit Report — Đảo Đèn Lồng

> Thời điểm audit: Phase 3 → Phase 4 transition
> Repository: `hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long`
> Tags hiện có: `phase-1` (`4c8f602`), `phase-2` (`f5d2062`)
> Branch hiện tại: `phase-3`

## Bảng tổng hợp trạng thái Audit

| Hạng mục | Đã có | Đang thiếu | Test | Trạng thái |
|---|---|---|---|---|
| **Phase 1 Baseline (`phase-1`)** | Tag `phase-1`, `main` nguyên vẹn tại `4c8f602`, 22 kịch bản cơ sở | Không | 22/22 PASS | **DONE** |
| **Phase 2 Core & Headless (`phase-2`)** | Tag `phase-2` tại `f5d2062`, 12-step tick order, 3 đêm, Jump/Dash/Bounce/Wind, Drifter/Charm, JSONL v1.1, `docs/proof/phase-2/EVIDENCE.md` | Đã phát hiện và sửa lỗi fall trừ 2 flame, stun decrement ở step 2, safe push khi thắp đèn trên nhánh `phase-3` | 34/34 scenario + unit regression PASS | **DONE** |
| **Phase 3 Contract v1.2 & Config** | `game.contract.json` v1.2, `Config.gd` strict validation kèm field path error | Không | `t_config_strict` (19 assertions) PASS | **DONE** |
| **Phase 3 Fuel, Refuel, Relight, Safe Push** | `fuel_units` (1/60), decay 1 unit/tick, drain 5 units/tick, first light (10), relight (5), refuel (`ceil`), `lantern_out`, safe zone `fuel >= 30`, safe push ≤ 30 ticks không gây sát thương | Không | `t_fuel_*`, `t_first_light`, `t_relight`, `t_refuel_*`, `t_safe_*` PASS | **DONE** |
| **Phase 3 Shade Drain & Dawn Survival** | State `drain`, wander tìm đèn yếu `<30` hoặc đèn tắt gần nhất, thoát drain đủ 6 điều kiện, `fuel_drain` mỗi 60 ticks, pulse drain +15 / thường +5, thắng `dawn_survived` (3/5, 4/6, 5/7), capacity `min(20, 10+2*lights)` | Không | Toàn bộ 28 nhóm test yêu cầu của TICKET-03 (225 assertions) PASS | **DONE** |
| **Phase 3 ADR & Changelog** | `docs/adr/ADR-003-lantern-fuel-and-dawn-survival.md`, `CHANGELOG.md`, `docs/notes/test-migration.md` | Cần thêm `docs/proof/phase-3/EVIDENCE.md` và hoàn thiện UI Colorblind trên 3D scene trước khi tag `phase-3` | Suite 225/225 PASS | **PARTIAL** |
| **Phase 3/4 3D View, Campaign, Colorblind & Accessibility UI** | `GameScene.gd` 3D cơ bản, `GameSettings.gd`, `CampaignController.gd`, `Leaderboard.gd` | Cần nâng cấp `GameScene.gd` / `Main.gd` để có Menu, Campaign 3 đêm, HUD fuel bar, Colorblind mode (màu `#00B3FF`, `#FFFFFF` + `⚠`, đèn tắt xẹp 20% + vết rách, nhấp nháy 1 Hz), Key Remap, Visual Indicators, Reduce Motion, Font ×1.25 | Cần thêm UI smoke test & Phase 4 unit tests | **PARTIAL** |
| **Phase 4 Benchmark (`bench_cmd`)** | `GameSim.init_bench`, `BenchStats.gd`, `ProcMem.gd` | Cần `src/bench.gd` scene runner (camera quỹ đạo 30m, Y=15m, 15s/vòng, warm-up 3s, đo 30s) và chạy xuất `bench.json` thật | Cần test công thức + chạy đo thật | **PARTIAL** |
| **Phase 4 Soak Test (`soak_cmd`)** | `src/tools/SoakRunner.gd`, `src/soak.gd` | Cần chạy thực tế 10 đêm xuất `soak.json` và unit test determinism cho soak | Cần chạy soak 10 đêm | **PARTIAL** |
| **Phase 4 Packaging, Docs, Retro, Release** | `CHANGELOG.md`, `docs/spec/TICKET-04.md` | `CREDITS.md`, `LICENSE`, `docs/retro/RETRO.md`, `docs/proof/phase-4/EVIDENCE.md`, cập nhật `README.md`, tag `phase-3`, branch & tag `phase-4`, build/release `v1.0.0` | Clean clone check | **NOT STARTED** |
