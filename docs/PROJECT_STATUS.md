# PROJECT STATUS — Đảo Đèn Lồng (v1.0.0)

| Phase | Milestone | Status | Test | Commit | Evidence |
|---|---|---|---|---|---|
| Phase 1 | Baseline gameplay & headless v1.0 | **DONE** | 22/22 PASS | `4c8f602` (`phase-1`) | `docs/proof/phase-1/EVIDENCE.md` |
| Phase 2 | Deterministic 12-step sim, 3 nights, v1.1 | **DONE** | 34/34 PASS | `f5d2062` (`phase-2`) | `docs/proof/phase-2/EVIDENCE.md` |
| Phase 3 | Fuel lifecycle, Shade drain, Dawn survival, ADR-003 | **DONE** | 225/225 PASS | `6eb7b72` | `docs/adr/ADR-003-lantern-fuel-and-dawn-survival.md` |
| Phase 3 | Colorblind 3D view & Phase 3 Evidence + Tag `phase-3` | **DONE** | 279/279 PASS | `39287c3` (`phase-3`) | `docs/proof/phase-3/EVIDENCE.md` |
| Phase 4 | Contract v1.3, Benchmark 3D (`bench.json`) & Soak 10 Nights (`soak.json`) | **DONE** | 283/283 PASS | `ccecd5f` (`phase-4`) | `bench.json`, `soak.json`, `docs/proof/phase-4/EVIDENCE.md` |
| Phase 4 | Persistent Leaderboard & Accessibility Settings UI (Unit + Windowed 3D Runtime) | **DONE** | 53/53 unit + 18/18 3D runtime PASS | `ccecd5f` (`phase-4`) | `docs/proof/phase-4/EVIDENCE.md`, `tests/ui/verify_runtime_p4.gd` |
| Phase 4 | Packaging, Docs (`README`, `CHANGELOG`, `CREDITS`, `LICENSE`, `RETRO`), Clean Clone, Tag `phase-4` & `v1.0.0` | **DONE** | Clean clone 283/283 PASS | `ccecd5f` (`v1.0.0`) | `docs/retro/RETRO.md`, `docs/proof/phase-4/regression_full_log.txt` |
| Release | Task A — Windows Standalone Build (`build/windows/DaoDenLong.exe` + `.pck`) | **DONE** | Export exit 0, GUI & CLI exit 0 from `$env:TEMP` | `release-finalization` | `docs/proof/release/windows-build.md`, `export_presets.cfg` |
| Release | Task B — Gameplay Demo MP4 (`docs/media/gameplay_demo.mp4`) | **DONE** | Verified MP4 (`2,571,352` B, H.264 `avc1`, `12.73s`) & uploaded to Release | `release-finalization` | `docs/proof/release/video-demo.md`, `docs/media/gameplay_demo.mp4` |
| Release | Task C — Docker Image Build (`dao-den-long:1.0.0`) | **BLOCKED** | `Dockerfile` verified against Godot 4.7.2 | `release-finalization` | `docs/proof/release/docker-build.md` (Docker CLI / daemon not installed on host machine) |
| Release | Task D — Official GitHub Release `v1.0.0` & Uploaded Artifacts (`DaoDenLong-v1.0.0-win64.zip`, `DaoDenLong.pck`, `gameplay_demo.mp4`, `bench.json`, `soak.json`) | **DONE** | HTTP 200 verified via GitHub Releases API (5 assets uploaded) | `release-finalization` | `docs/proof/release/github-release.md`, `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/tag/v1.0.0` |
