# EVIDENCE.md — Phase 4 Verification ("Bình Minh · Release v1.0.0")

> Repo: `hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long`
> Branch / Tag: `phase-4`
> Contract: `v1.3` (`docs/spec/TICKET-04.md`)
> ADR: `docs/adr/ADR-004-bench-soak-leaderboard.md`
> Test suite: `bash tests/run_tests.sh` → **283 passed, 0 failed**

---

## 1. Benchmark 3D Thực tế (`bench.json` — TICKET-04 §3.1)

Lệnh đã thực thi:
```bash
godot --path . --script res://src/bench.gd -- --seed 42 --duration 30 --out bench.json
```

Cấu hình cảnh đo:
- Độ phân giải cửa sổ: `1280×720` (Windowed, không fullscreen), `VSync = Disabled` (`vsync_off: true`).
- Bản đồ: Night 1 (Đảo Bến), đầy đủ hiệu ứng ánh sáng (`WorldEnvironment` glow, `DirectionalLight3D`, 3 `OmniLight3D` trên L1–L3 với `fuel = 100`).
- Thực thể: Chính xác **200 Shade** trạng thái `wander` phân bố đều trên đảo (`seed = 42`), chính xác **100 mote**, player đứng tại `(0,0,0)`.
- Tắt spawn, damage, pickup, fuel decay và điều kiện kết thúc; 200 Shade vẫn di chuyển `wander` bình thường.
- Camera: Quỹ đạo tròn tâm `(0,0,0)`, bán kính `30 m`, `Y = 15 m`, nhìn về gốc tọa độ, xuất phát tại `(30, 15, 0)` (góc `0°`), quay ngược chiều kim đồng hồ `15 s/vòng`.
- Warm-up `3.0 s` không đo, sau đó đo chính xác `30.0 s` và tự thoát với mã `0`.

Kết quả đo thực tế (`bench.json`):
```json
{
  "avg_fps": 163.9,
  "contract_version": "1.3",
  "frame_ms_p95": 10.8,
  "frames": 4919,
  "load_ms": 647,
  "os": "Windows (10.0.26200)",
  "p1_low_fps": 62.2,
  "peak_mem_mb": 241,
  "renderer": "Godot 4.7.2-stable (official) / gl_compatibility / Intel(R) Iris(R) Xe Graphics",
  "vsync_off": true
}
```

| Chỉ số | Giá trị đo thực tế | Ngưỡng giảng viên | Đánh giá |
|---|---:|---:|---|
| `avg_fps` | **163.9 FPS** | `>= 60.0 FPS` | ✅ **PASS** (gấp 2.7× ngưỡng) |
| `p1_low_fps` | **62.2 FPS** | `>= 30.0 FPS` | ✅ **PASS** (gấp 2.0× ngưỡng) |
| `load_ms` | **647 ms** | `<= 10000 ms` | ✅ **PASS** (nhanh hơn 15× ngưỡng) |
| `frame_ms_p95` | **10.8 ms** | — | ✅ Ổn định |
| `peak_mem_mb` | **241 MB** | — | ✅ Working-set đỉnh thực tế từ OS |

---

## 2. Soak Test 10 Đêm Liên Tiếp Cùng Process (`soak.json` — TICKET-04 §3.2)

Lệnh đã thực thi:
```bash
godot --headless --path . --script res://src/soak.gd -- --seed 7 --nights 10 --out soak.json
```

Cấu hình:
- Chạy **10 Night liên tiếp trong cùng một tiến trình Godot** (`src/soak.gd` → `SoakRunner.run`).
- Chu kỳ Night: `1 → 2 → 3 → 1 → 2 → 3 → 1 → 2 → 3 → 1`.
- Night thứ `i` (`i = 0..9`) dùng seed `7 + i`.
- Input ngẫu nhiên tất định: mỗi 30 tick chọn lại hướng di chuyển; mỗi tick xác suất `5% jump`, `3% dash`, `2% pulse`, `10% interact`.

Kết quả đo thực tế (`soak.json`):
```json
{
  "crashes": 0,
  "duration_s": 1.7,
  "mem_end_mb": 91.2,
  "mem_start_mb": 91.1,
  "nights": 10,
  "results": [
    "lost",
    "lost",
    "lost",
    "lost",
    "lost",
    "lost",
    "lost",
    "lost",
    "lost",
    "lost"
  ]
}
```

| Chỉ số | Giá trị đo thực tế | Ngưỡng giảng viên | Đánh giá |
|---|---:|---:|---|
| `crashes` | **0** | `= 0` | ✅ **PASS** |
| `mem_start_mb` | **91.1 MB** | — | RSS ngay sau khi load xong Night đầu |
| `mem_end_mb` | **91.2 MB** | `<= 1.2 * mem_start_mb` (`<= 109.32 MB`) | ✅ **PASS** (chênh lệch `+0.1 MB` / `+0.11%`) |

---

## 3. Requirement → Evidence Matrix (TICKET-04)

| # | Yêu cầu TICKET-04 | Nguồn | File / Test xác minh | Kết quả |
|---|---|---|---|---|
| 1 | Contract v1.3 (`bench_cmd`, `soak_cmd`) | §1, §3.7 | `game.contract.json`, `src/core/Config.gd` | ✅ PASS |
| 2 | Benchmark 3D 1280×720, 200 Shade wander, 100 mote, L1–L3 lit fuel 100, camera orbit R=30m Y=15m 15s/vòng CCW, warm-up 3s, đo 30s | §3.1 | `src/bench.gd`, `src/core/BenchStats.gd`, `bench.json`, `run_unit_p4.gd::t_bench_workload_and_stats` | ✅ PASS |
| 3 | Soak test 10 Night cùng process, cycle 1→2→3, seed `7+i`, random input (30t dir, 5% jump, 3% dash, 2% pulse, 10% interact), RSS memory check | §3.2 | `src/soak.gd`, `src/tools/SoakRunner.gd`, `soak.json`, `run_unit_p4.gd::t_soak_determinism` | ✅ PASS |
| 4 | Leaderboard local: Top 10, name `3–12` ký tự `[A-Za-z0-9_]`, sort score giảm dần, tie-break timestamp, campaign score cộng các Night thắng, chịu lỗi file hỏng, CLI `--export-leaderboard out.json` | §3.3 | `src/core/Leaderboard.gd`, `src/core/CampaignController.gd`, `src/gameplay/GameScene.gd`, `run_unit_p4.gd` (23 assertions), `run_tests.sh::P4-CLI` | ✅ PASS |
| 5 | Accessibility — Key remapping (9 hành động, phát hiện trùng phím, thông báo lỗi, khôi phục mặc định, lưu/load) | §3.4 | `src/core/GameSettings.gd`, `src/gameplay/GameScene.gd`, `run_unit_p4.gd::t_settings_remapping_and_font` | ✅ PASS |
| 6 | Accessibility — Visual indicators (Shade xuất hiện, mũi tên chỉ hướng Shade ở mép màn hình, gió sắp thổi, 10 giây cuối, đèn `fuel < 30`) | §3.4 | `src/gameplay/GameScene.gd` (`_update_hud`, `_update_edge_arrows`, `_handle_sim_events`) | ✅ PASS |
| 7 | Accessibility — Reduce motion (tắt rung camera, tắt chớp màn hình, giữ chỉ báo văn bản/biểu tượng) & Font (`>= 18 px` ở 1280×720, tùy chọn chữ lớn `×1.25`) | §3.4 | `src/core/GameSettings.gd`, `src/gameplay/GameScene.gd`, `run_unit_p4.gd` | ✅ PASS |
| 8 | Packaging & Documentation: `README.md` (≤ 3 lệnh chạy ngay + screenshot thực tế `docs/media/gameplay.png`), `CHANGELOG.md` (đủ Phase 1–4), `CREDITS.md`, `LICENSE` (MIT), `docs/retro/RETRO.md` (1–2 trang) | §3.5 | Các file tương ứng trong repo | ✅ PASS |

---

## 4. Ghi nhận Giới hạn Môi trường (Blockers) — Trung thực 100%

Theo nguyên tắc không giả mạo binary, video MP4 hay GitHub Release:
1. **Godot Export Templates (Desktop Binary / Web Build):**
   - Thư mục `%APPDATA%\Godot\export_templates` trên máy hiện tại trống (chưa cài gói ~1 GB export templates của Godot 4.7.2).
   - **Giải pháp đã hoàn thiện:** Tạo `scripts/build_release.sh`, `scripts/build_release.ps1` và `Dockerfile` (cho phép chạy qua Docker image hoặc chạy trực tiếp từ source bằng `godot --path .`).
2. **Ghi video Demo MP4 (`< 5 phút`):**
   - Môi trường CLI hiện tại không cài `ffmpeg`, `OBS` hay thư viện mã hóa H.264 (`cv2`/`imageio`/`moviepy`).
   - **Giải pháp đã hoàn thiện:** Chụp screenshot 3D thực tế `docs/media/gameplay.png` (`1280×720`) từ engine và biên soạn kịch bản quay chi tiết từng phân cảnh tại `docs/demo/DEMO_CHECKLIST.md`.
3. **Tạo GitHub Release `v1.0.0` trên giao diện web GitHub:**
   - Môi trường không cài `gh` (GitHub CLI) và không có biến môi trường `GITHUB_TOKEN` cho REST API (chỉ có quyền `git push` nhánh và tag qua HTTPS credential helper).
   - **Giải pháp đã hoàn thiện:** Đẩy đầy đủ branch `phase-3`, tag `phase-3`, branch `phase-4`, tag `phase-4` và tag `v1.0.0` lên `origin`, đồng thời chuẩn bị sẵn nội dung Release Notes chuẩn tại `docs/proof/phase-4/RELEASE_NOTES_v1.0.0.md`.
