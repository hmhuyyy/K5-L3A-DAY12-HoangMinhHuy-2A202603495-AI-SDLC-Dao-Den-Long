# Evidence — Task D: GitHub Release `v1.0.0`

## 1. Những gì đã kiểm tra
- Kiểm tra tag `v1.0.0` trên remote `origin`:
  - `ccecd5f3c9dda6b9c043e1557c0cb7fb61342fd6 refs/tags/v1.0.0` (không tạo tag mới, không di chuyển tag cũ).
- Kiểm tra quyền truy cập GitHub REST API thông qua Git Credential Manager của máy:
  - User: `hmhuyyy` (`permissions: {'admin': True, 'maintain': True, 'push': True}`).
  - Hoàn toàn không lưu hay in token ra mã nguồn hoặc log.

## 2. Những gì đã thực hiện
- Đã tạo chính thức GitHub Release cho tag `v1.0.0`:
  - **Release Title:** `Đảo Đèn Lồng v1.0.0`
  - **Release URL:** `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/tag/v1.0.0`
  - **Release Notes:** Tổng hợp từ [CHANGELOG.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/CHANGELOG.md) và [docs/proof/phase-4/RELEASE_NOTES_v1.0.0.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/proof/phase-4/RELEASE_NOTES_v1.0.0.md).
- Đã upload và xác minh đầy đủ **5 artifacts thực tế** lên GitHub Release `v1.0.0`:

| Asset Name | State | Size (Bytes) | Download URL |
|---|---|---:|---|
| `DaoDenLong-v1.0.0-win64.zip` | `uploaded` | `38,224,616` | `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/download/v1.0.0/DaoDenLong-v1.0.0-win64.zip` |
| `DaoDenLong.pck` | `uploaded` | `166,612` | `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/download/v1.0.0/DaoDenLong.pck` |
| `gameplay_demo.mp4` | `uploaded` | `2,571,352` | `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/download/v1.0.0/gameplay_demo.mp4` |
| `bench.json` | `uploaded` | `306` | `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/download/v1.0.0/bench.json` |
| `soak.json` | `uploaded` | `241` | `https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long/releases/download/v1.0.0/soak.json` |

## 3. Trạng thái
- **Status:** **DONE (PASS)**
