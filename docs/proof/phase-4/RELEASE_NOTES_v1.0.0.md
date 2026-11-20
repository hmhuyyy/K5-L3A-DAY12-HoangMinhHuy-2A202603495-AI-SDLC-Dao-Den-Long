# Release Notes — Đảo Đèn Lồng v1.0.0 (Phase 4 · Contract v1.3)

## Tổng quan
Bản phát hành chính thức **v1.0.0** của **Đảo Đèn Lồng (Lantern Island)** trên **Godot 4.7.2**, hoàn thiện toàn bộ lộ trình Phase 1 → Phase 2 → Phase 3 → Phase 4 (`Contract v1.0 → v1.1 → v1.2 → v1.3`).

## Tính năng nổi bật
- **Chiến dịch 3 Đêm (Đảo Bến, Đảo Cau, Đảo Chuông):** Vật lý nhảy, lướt (`dash`), bục nhảy (`bounce pad`), gió thổi chu kỳ (Đêm 3), Gió Lạc (`Drifter`) và Bùa Gió (`Charm`).
- **Mô hình Nhiên liệu Đèn & Sống sót đến Bình Minh (`Contract v1.2`):**
  - Đèn sáng có `fuel = 100` (lưu nội bộ `6000 units` nguyên `1/60`), tự hao `1.0/s`.
  - Thắp mới (`10 mote`, `+100` điểm), thắp lại (`5 mote`, `+40` điểm), châm dầu (`ceil((100 - fuel)/10)`, `+5/mote`).
  - Vùng an toàn bán kính `6 m` khi `fuel >= 30`; đẩy Bóng Mực ra rìa trong `<= 30 ticks` khi đèn vừa đạt ngưỡng an toàn.
  - Bóng Mực hút dầu (`drain`, `5 fuel/s` mỗi con, cộng dồn) ở đèn yếu `fuel < 30`.
  - Sức chứa tăng dần `capacity = min(20, 10 + 2 * successful_lights)`.
  - Thắng `dawn_survived` khi sống sót đến hết giờ với tối thiểu 60% đèn sáng (`3/5`, `4/6`, `5/7`).
- **Hiệu năng, Độ ổn định & Trợ năng (`Contract v1.3`):**
  - **Benchmark 3D (`bench_cmd`):** 200 Shade wander, 100 mote, L1–L3 lit ở `1280×720` đạt **`163.9 avg_fps`**, **`62.2 p1_low_fps`**, **`647 ms load_ms`**.
  - **Soak Test 10 Đêm (`soak_cmd`):** 10 Đêm liên tiếp cùng process đạt **`0 crashes`**, bộ nhớ `91.1 MB → 91.2 MB` (`+0.11%`).
  - **Bảng xếp hạng Local (Top 10):** Lưu điểm chiến dịch bền vững, chịu lỗi file hỏng, xuất CLI `--export-leaderboard`.
  - **Trợ năng toàn diện:** Chế độ **Bảng màu dễ phân biệt** (`#00B3FF`, `#FFFFFF + ⚠`, đèn tắt xẹp 20% + vết giấy rách, thanh nhiên liệu 3D, nhấp nháy 1 Hz), đổi phím (Key Remapping) cho 9 hành động có phát hiện trùng phím, mũi tên báo hướng Bóng Mực ngoài màn hình, Giảm chuyển động (Reduce Motion) và Chữ lớn `×1.25`.

## Cài đặt và Chạy (3 lệnh)
```bash
git clone https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long.git
cd K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long
godot --path .
```
