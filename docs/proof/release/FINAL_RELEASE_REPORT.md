# FINAL RELEASE REPORT — Đảo Đèn Lồng v1.0.0

> Repository: `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long.git`
> Release Branch: `release-finalization` (branched from `phase-4` / `v1.0.0` at `ccecd5f3c9dda6b9c043e1557c0cb7fb61342fd6`)
> GitHub Release URL: `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/tag/v1.0.0`

---

## 1. Bảng Tổng kết Trạng thái Deliverables (Task A – Task D)

| Deliverable | Status | Evidence | Notes |
|---|---|---|---|
| **Windows standalone build** | **DONE** | [docs/proof/release/windows-build.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/proof/release/windows-build.md), [export_presets.cfg](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/export_presets.cfg), `build/windows/DaoDenLong.exe` (`109,268,480` B), `build/windows/DaoDenLong.pck` (`166,612` B), `build/DaoDenLong-v1.0.0-win64.zip` (`38,224,616` B) | Đã cài bộ Windows export templates chính thức của Godot 4.7.2, chạy `--export-release "Windows Desktop" build/windows/DaoDenLong.exe` với `exit code 0`, kiểm chứng chạy độc lập cả chế độ GUI 3D (`exit 0`) và CLI `--export-leaderboard` (`exit 0`) từ `$env:TEMP`. |
| **Gameplay demo MP4** | **DONE** | [docs/proof/release/video-demo.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/proof/release/video-demo.md), [docs/media/gameplay_demo.mp4](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/media/gameplay_demo.mp4) (`2,571,352` B), [docs/demo/RECORDING_GUIDE.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/demo/RECORDING_GUIDE.md) | File MP4 H.264 (`ftypmp42`, `avc1`, `738×498`, `12.73s < 5 phút`, SHA-256 `6e80b13f...27b`) đã được kiểm chứng và upload lên GitHub Release `v1.0.0`. |
| **Docker image** | **BLOCKED** | [docs/proof/release/docker-build.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/proof/release/docker-build.md), [Dockerfile](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/Dockerfile) | Máy không cài Docker CLI / Docker daemon (`Get-Command docker` không có kết quả). Đã đối chiếu và chuẩn hóa `Dockerfile` cho Godot 4.7.2 (`ubuntu:24.04`). |
| **GitHub Release** | **DONE** | [docs/proof/release/github-release.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/proof/release/github-release.md), `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/tag/v1.0.0` | Đã tạo GitHub Release chính thức `Đảo Đèn Lồng v1.0.0` tại tag `v1.0.0` và upload thành công cả 5 artifacts: `DaoDenLong-v1.0.0-win64.zip`, `DaoDenLong.pck`, `gameplay_demo.mp4`, `bench.json` và `soak.json`. |

---

## 2. Xác minh Tính toàn vẹn của Dự án

- **Gameplay & Core Simulation:** Không sửa bất kỳ file nào trong `src/`, `tests/`, `game.contract.json`, `bench.json` hay `soak.json`.
- **Branches & Tags Phase 1–4:**
  - `main` / `phase-1`: `4c8f602c45a8d5b91b7d597115b22996e96bbe23` (nguyên vẹn)
  - `phase-2`: `f5d20622bd418ff3703b61c8f92083b88225faa5` (nguyên vẹn)
  - `phase-3`: `39287c31dc6564f2aee373525383c35cb2f7a621` (nguyên vẹn)
  - `phase-4` / `v1.0.0`: `ccecd5f3c9dda6b9c043e1557c0cb7fb61342fd6` (nguyên vẹn)
- **Bảo mật:** Không lưu bất kỳ token, mật khẩu hay thông tin nhạy cảm nào vào mã nguồn hoặc lịch sử Git.
