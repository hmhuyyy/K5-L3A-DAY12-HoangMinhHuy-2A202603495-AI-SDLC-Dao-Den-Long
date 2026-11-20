# PROJECT STATUS — Đảo Đèn Lồng (v1.0.0)

| Phase | Milestone | Status | Test | Commit | Evidence |
|---|---|---|---|---|---|
| Phase 1 | Baseline gameplay & headless v1.0 | **DONE** | 22/22 PASS | `4c8f602` (`phase-1`) | `docs/proof/phase-1/EVIDENCE.md` |
| Phase 2 | Deterministic 12-step sim, 3 nights, v1.1 | **DONE** | 34/34 PASS | `f5d2062` (`phase-2`) | `docs/proof/phase-2/EVIDENCE.md` |
| Phase 3 | Fuel lifecycle, Shade drain, Dawn survival, ADR-003 | **DONE** | 225/225 PASS | `6eb7b72` | `docs/adr/ADR-003-lantern-fuel-and-dawn-survival.md` |
| Phase 3 | Colorblind 3D view & Phase 3 Evidence + Tag `phase-3` | **DONE** | 279/279 PASS | `39287c3` (`phase-3`) | `docs/proof/phase-3/EVIDENCE.md` |
| Phase 4 | Contract v1.3, Benchmark 3D (`bench.json`) & Soak 10 Nights (`soak.json`) | **DONE** | 283/283 PASS | `phase-4` HEAD | `bench.json`, `soak.json`, `docs/proof/phase-4/EVIDENCE.md` |
| Phase 4 | Persistent Leaderboard & Accessibility Settings UI (Unit + Windowed 3D Runtime) | **DONE** | 53/53 unit + 18/18 3D runtime PASS | `phase-4` HEAD | `docs/proof/phase-4/EVIDENCE.md`, `tests/ui/verify_runtime_p4.gd` |
| Phase 4 | Packaging, Docs (`README`, `CHANGELOG`, `CREDITS`, `LICENSE`, `RETRO`), Clean Clone, Tag `phase-4` & `v1.0.0` | **DONE** | Clean clone 283/283 PASS | `phase-4` (`v1.0.0`) | `docs/retro/RETRO.md`, `docs/proof/phase-4/regression_full_log.txt` |
| Phase 4 | Standalone Binary Export / Docker Image Build / Demo MP4 / Web GitHub Release Asset Upload | **BLOCKED** | Scripts & checklists ready (`Dockerfile`, `scripts/build_release.sh`, `docs/demo/DEMO_CHECKLIST.md`, `RELEASE_NOTES_v1.0.0.md`) | `phase-4` (`v1.0.0`) | Missing Godot 4.7.2 export templates, `docker`, `ffmpeg`/MP4 encoder, and `gh`/`GITHUB_TOKEN` on host machine |
