# RECORDING GUIDE — Hướng dẫn Quay Video Gameplay Demo MP4 (2–3 phút)

> Dự án: **Đảo Đèn Lồng v1.0.0** (Godot 4.7.2)
> File đích cần lưu sau khi quay: `docs/media/gameplay_demo.mp4`

---

## 1. Công cụ quay màn hình sẵn có trên máy

Trên máy Windows hiện tại đã cài sẵn **Xbox Game Bar** (`Microsoft.XboxGamingOverlay`). Bạn cũng có thể dùng **OBS Studio** nếu muốn.

### Cách A — Dùng Xbox Game Bar (Sẵn có trên Windows 10/11)
1. Mở game ở chế độ cửa sổ `1280×720`:
   - Chạy trực tiếp bản build độc lập: `.\build\windows\DaoDenLong.exe`
   - Hoặc chạy từ mã nguồn: `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe --path .`
2. Click vào cửa sổ **DaoDenLong** để active cửa sổ.
3. Nhấn tổ hợp phím **`Win + Alt + R`** để bắt đầu quay (hoặc `Win + G` để mở bảng điều khiển Xbox Game Bar rồi bấm nút **Record**).
4. Thực hiện đầy đủ kịch bản 8 bước ở Mục 2 bên dưới (khoảng **2 – 3 phút**).
5. Nhấn **`Win + Alt + R`** một lần nữa để dừng quay.
6. Video MP4 sẽ được Windows lưu tự động tại thư mục `C:\Users\Admin\Videos\Captures\`.
7. Copy hoặc di chuyển file `.mp4` vừa quay vào đường dẫn:
   ```powershell
   Copy-Item "$env:USERPROFILE\Videos\Captures\*.mp4" "docs\media\gameplay_demo.mp4"
   ```

### Cách B — Dùng OBS Studio
1. Mở OBS Studio → trong mục **Sources**, thêm **Window Capture** và chọn cửa sổ `DaoDenLong (1280x720)`.
2. Trong **Settings → Output → Recording**, chọn **Recording Format: `mp4 (H.264)`**.
3. Bấm **Start Recording**, chơi theo kịch bản Mục 2 trong 2–3 phút, bấm **Stop Recording** và lưu file thành `docs/media/gameplay_demo.mp4`.

---

## 2. Kịch bản thao tác bắt buộc trong Video (2 – 3 phút)

Để video đạt chuẩn nghiệm thu Phase 4 (`v1.0.0`), hãy thực hiện tuần tự các thao tác sau trong một lần quay:

1. **Mở game & Bắt đầu chơi (0:00 – 0:20):**
   - Khởi động game, mở **Menu** ở góc phải trên cùng, bấm **"Chơi chiến dịch mới (Đêm 1 → 3)"**.
   - Quan sát HUD hiển thị: `Đêm 1 | Đom đóm: 0 / 10 | Đèn sáng: 0/5 (cần 3) | Lửa: 3 | Điểm: 0 | Còn: 240s`.
2. **Thu thập đom đóm (`mote`) (0:20 – 0:50):**
   - Dùng `W / A / S / D` di chuyển Mây, `Space` để nhảy và `Shift` để lướt (`Dash`) thu thập đủ 10 đom đóm phát sáng trên mặt đảo (`Đom đóm: 10 / 10`).
3. **Thắp đèn lồng lần đầu & Tăng sức chứa (`capacity`) (0:50 – 1:15):**
   - Đi tới gần trụ đèn `L1` (cách `<= 2m`), nhấn **`E`** để nạp 10 đom đóm.
   - Đèn `L1` bùng sáng (`fuel = 100`), thanh nhiên liệu 3D hiện lên phía trên đèn, điểm tăng `+150` (`10×5 + 100`), và sức chứa trên HUD tăng lên **`0 / 12`**.
4. **Tiếp nhiên liệu (`refuel`) & Thắp lại đèn (`relight`) (1:15 – 1:45):**
   - Nhặt thêm vài đom đóm, quay lại đèn đang sáng chưa đầy dầu và nhấn **`E`** để châm thêm dầu (`refuel`, `+5 điểm/mote`).
5. **Cho thấy Bóng Mực hút dầu (`Shade drain`) & Cảnh báo nhiên liệu thấp (1:45 – 2:10):**
   - Khi một đèn giảm xuống `fuel < 30`, đèn nhấp nháy chậm `1 Hz`, HUD hiện cảnh báo `⚠ Đèn sắp cạn dầu (<30)` và mũi tên `⚠ Bóng Mực` chỉ hướng ở mép màn hình.
   - Quan sát Bóng Mực tiến vào đèn yếu và đứng yên hút dầu (`drain`, `5 fuel/s`).
6. **Dùng Tỏa Sáng (`Pulse` — phím `Q`) (2:10 – 2:25):**
   - Khi đang mang ít nhất 3 đom đóm, tiến lại gần Bóng Mực (trong bán kính `5m`) và nhấn **`Q`**.
   - Bóng Mực bị đẩy lùi `4m` và choáng nhấp nháy trong `120 ticks` (`+15 điểm` nếu đang hút dầu, `+5 điểm` nếu bình thường).
7. **Hiển thị Cài đặt & Trợ năng (`Settings`) (2:25 – 2:45):**
   - Bấm nút **Cài đặt** ở góc trên bên phải:
     - Bật **"Bảng màu dễ phân biệt"** (Bóng Mực chuyển sang màu xanh `#00B3FF`, cảnh báo chuyển sang `#FFFFFF + ⚠`; đèn tắt xẹp 20% kèm vết giấy rách).
     - Bật **"Giảm chuyển động"** và **"Chữ lớn ×1.25"**.
     - Thử bấm đổi một phím điều khiển rồi bấm **"Khôi phục mặc định"**.
8. **Hiển thị Kết quả Đêm & Bảng xếp hạng (`Leaderboard`) (2:45 – 3:00):**
   - Hoàn thành đêm (hoặc để hết Ngọn Lửa để mở màn hình Kết thúc), nhập tên người chơi (`3–12` ký tự `[A-Za-z0-9_]`, ví dụ `MAY_01`), bấm **"Lưu điểm vào Bảng xếp hạng"** để hiển thị bảng **Top 10 Local Leaderboard**.

---

## 3. Kiểm tra sau khi quay

Sau khi lưu file `docs/media/gameplay_demo.mp4`, kiểm tra nhanh trong PowerShell:

```powershell
Get-Item docs\media\gameplay_demo.mp4 | Select-Object Name, Length, LastWriteTime
```
(Đảm bảo dung lượng file `> 1 MB`, thời lượng `< 5 phút`, mở xem được bình thường).
