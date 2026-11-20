# Evidence — Task B: Gameplay Demo MP4

## 1. Những gì đã kiểm tra
- Kiểm tra sự tồn tại của `docs/media/gameplay_demo.mp4` và tìm kiếm toàn bộ file `*.mp4` trong repository:
  ```powershell
  Test-Path docs/media/gameplay_demo.mp4   # -> False
  Get-ChildItem -Recurse -Filter *.mp4     # -> (none)
  ```
- Kiểm tra các công cụ quay và mã hóa video trên máy:
  - `Get-Command ffmpeg` → **Không tìm thấy** (`ffmpeg` chưa được cài đặt).
  - Python packages (`cv2`, `imageio`, `av`, `moviepy`) → **Không tìm thấy** (chỉ có `PIL`).
  - `Get-AppxPackage *XboxGamingOverlay*` → **Có sẵn** (`Microsoft.XboxGamingOverlay` — Xbox Game Bar của Windows 10/11).

## 2. Những gì đã thực hiện
- Tuân thủ nghiêm ngặt nguyên tắc: **Không giả lập gameplay video bằng ảnh tĩnh, slideshow hoặc tạo file `.mp4` giả**.
- Đã biên soạn hướng dẫn quay gameplay thực tế chi tiết từng bước bằng **Xbox Game Bar (`Win + Alt + R`)** hoặc **OBS Studio** tại:
  - [docs/demo/RECORDING_GUIDE.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/demo/RECORDING_GUIDE.md)
  - Bao gồm đầy đủ 8 phân cảnh yêu cầu trong 2–3 phút: mở game, bắt đầu chơi, thu thập mote, thắp và tiếp nhiên liệu cho đèn, Bóng Mực hút dầu (`drain`), dùng Tỏa Sáng (`Pulse`), hiển thị kết quả đêm, hiển thị Leaderboard và Settings/Accessibility.

## 3. Trạng thái
- **Status:** **BLOCKED** (Cần người dùng thao tác trực tiếp trên GUI với Xbox Game Bar / OBS theo [docs/demo/RECORDING_GUIDE.md](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/docs/demo/RECORDING_GUIDE.md) để tạo file `docs/media/gameplay_demo.mp4` thật).
