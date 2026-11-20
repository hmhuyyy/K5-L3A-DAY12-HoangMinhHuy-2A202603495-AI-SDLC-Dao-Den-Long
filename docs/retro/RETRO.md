# RETROSPECTIVE — Đảo Đèn Lồng (Phase 1 → Phase 4 · Release v1.0.0)

> Tác giả: Hoàng Minh Huy (`2A202603495`) · Dự án: Đảo Đèn Lồng (Godot 4.7.2)

---

## 1. Đánh giá tổng quan qua 4 Phase

| Phase | Contract | Mục tiêu cốt lõi | Kết quả & Bài học chính |
|---|---|---|---|
| **Phase 1** | `v1.0` | Xây dựng lõi simulation tất định (`GameSim`), headless JSONL pipeline và 3D passive view cho Đêm 1 (5 đèn). | Tách biệt hoàn toàn `src/core/` (không phụ thuộc `Node3D`/`Viewport`) với `src/gameplay/`. 22/22 test kịch bản nền tảng xanh, đặt nền móng cho toàn bộ dự án. |
| **Phase 2** | `v1.1` | Mở rộng lên 3 Đêm (Đảo Bến, Đảo Cau, Đảo Chuông), vật lý nhảy/lướt/bục nhảy/gió, Gió Lạc, Bùa Gió, rơi khỏi đảo, pause (`executed_ticks` vs `sim_tick`), thứ tự tick 12 bước. | Viết lại `GameSim` theo đúng 12 bước xử lý. Mọi hằng số đưa vào `game.contract.json` và đọc qua `Config.gd`. 34/34 kịch bản đạt, benchmark headless cả 3 đêm dưới 3 giây (ngưỡng ≤ 30 giây). |
| **Phase 3** | `v1.2` | Change Request "Đèn Cạn Dầu": mô hình nhiên liệu đèn, thắp mới/thắp lại/châm dầu, Bóng Mực hút dầu (`drain`), vùng an toàn phụ thuộc `fuel >= 30`, sống sót đến bình minh (`dawn_survived`), capacity tăng dần, bảng màu dễ phân biệt. | Xóa bỏ hoàn toàn luật thắng sớm `all_lit` và thưởng thời gian cũ để tránh xung đột. Lưu nhiên liệu theo đơn vị nguyên `1/60` (`fuel_units`, đầy = `6000`) giúp loại bỏ triệt để sai số dấu phẩy động. 225+ assertions bao phủ toàn bộ 28 nhóm yêu cầu. |
| **Phase 4** | `v1.3` | Benchmark 3D 200 Shade + 100 mote (`bench_cmd`), Soak test 10 Đêm liên tiếp cùng process (`soak_cmd`), Leaderboard local (top 10 + CLI export), Accessibility (remap phím, chỉ báo hình ảnh, giảm chuyển động, chữ lớn ×1.25), đóng gói phát hành `v1.0.0`. | Hoàn thiện công cụ đo hiệu năng thực tế trên GPU và đo RSS working-set, xác minh không rò rỉ bộ nhớ qua 10 đêm liên tiếp, bổ sung 53 unit/UI assertions nâng tổng số kiểm thử tự động lên hơn 280 assertions. |

---

## 2. Điều gì hiệu quả và không hiệu quả khi làm việc với AI

### Hiệu quả cao
- **Kiến trúc "Core thuần dữ liệu + Headless JSONL Contract":** Vì `GameSim` không chạm tới `Node3D`, AI có thể chạy hàng trăm kịch bản kiểm thử trong vài giây qua CLI mà không cần mở cửa sổ đồ họa.
- **Đặc tả hóa thành ADR trước khi code:** Khi chuyển từ Phase 2 sang Phase 3 (`TICKET-03`), việc buộc AI lập bảng trạng thái đèn và thứ tự ưu tiên thoát `drain` trong `ADR-003` giúp code `GameSim.gd` sạch và không sót nhánh biên.
- **Kiểm thử đơn vị trong cùng process (`run_unit.gd`, `run_unit_p4.gd`):** Thay vì khởi động 150 tiến trình Godot riêng lẻ (tốn thời gian khởi tạo), gom các bài test đơn vị vào một `SceneTree` script giúp chạy hơn 220 assertions chỉ trong ~2 giây.

### Chưa hiệu quả nếu không kiểm soát
- **Thao tác chuỗi đa dòng qua shell trên Windows PowerShell:** Khi dùng one-liner Python bên trong PowerShell để sửa file lớn, quy tắc escape dấu nháy kép/nháy đơn của PowerShell dễ gây lỗi cú pháp. Giải pháp hiệu quả hơn là dùng công cụ sửa file trực tiếp hoặc viết script Python ra thư mục tạm `out/` rồi thực thi.
- **Giả định ngầm về vòng đời Node của Godot khi chạy headless:** Khi kiểm thử `GameScene.tscn` từ bên trong `_init()` của một `SceneTree` test script, `get_root()` chưa phát tín hiệu `ready` tự động cho node con và `get_viewport()` hoặc `is_inside_tree()` có hành vi khác với lúc chạy main loop thông thường.

---

## 3. Những lần AI sai và cách phát hiện / khắc phục

1. **Lỗi rơi khỏi đảo trừ 2 lần Ngọn Lửa (phát hiện khi audit Phase 2 → Phase 3):**
   - *Mô tả lỗi:* Trong code Phase 2 ban đầu, `player.flames -= 1` được gọi một lần khi `player.pos.y < -10` (bắt đầu rơi) và bị gọi thêm một lần nữa sau 60 tick chờ hồi sinh.
   - *Cách phát hiện:* Đọc chéo `GameSim._step_fall()` với `TICKET-02` ("Xảy ra đúng 1 lần, bỏ qua bất tử: −1 Ngọn Lửa") và viết unit test `t_fall_single_flame` theo dõi suốt 70 tick từ lúc rơi đến sau hồi sinh.
   - *Khắc phục:* Chỉ trừ `flames` đúng thời điểm bắt đầu rơi; khi hết 60 tick chỉ đặt lại vị trí, vận tốc và `invuln_ticks = 90`.
2. **Lỗi thời điểm giảm bộ đếm choáng (`state_ticks_left`) của Bóng Mực:**
   - *Mô tả lỗi:* Bản đầu giảm `state_ticks_left` ở bước 8 (`_step_shade_one`) thay vì bước 2 (`_step_counters`), khiến khi Pulse ở bước 7 đặt `state_ticks_left = 120`, ngay bước 8 cùng tick đó nó đã bị trừ xuống 119 (choáng thực tế chỉ còn 119 tick).
   - *Cách phát hiện:* Viết unit test `t_stun_timing` kiểm tra chính xác tick thứ 119 (còn choáng) và tick thứ 120 (hết choáng).
   - *Khắc phục:* Chuyển bộ đếm trạng thái tạm thời (`stunned`, `recoil`) của Shade về đúng Bước 2 theo thứ tự 12 bước của `TICKET-02`.
3. **Lỗi thứ tự Bước 2 (Fuel decay) và Bước 5 (Lantern interaction) trong cùng một tick:**
   - *Mô tả lỗi:* Khi đặt một đèn sáng có `fuel = 100` ở tick 0 rồi nhấn `interact` ở tick 1, Bước 2 chạy trước Bước 5 nên đèn đã hao 1 unit (`5999 / 6000 = 99.983`), khiến đèn không còn "đầy tuyệt đối" tại thời điểm Bước 5 kiểm tra.
   - *Cách phát hiện:* Test `t_refuel_full_noop` báo `refuel` 1 mote khi chạy qua `tick()`.
   - *Khắc phục:* Phân biệt rõ trong test và `ADR-003`: qua một tick đầy đủ thì đèn đã hao 1 unit nên châm 1 mote là đúng luật; còn khi kiểm tra trực tiếp `_step_lantern_interact` với đèn có `fuel_units == 6000`, hàm bỏ qua hoàn toàn (0 mote, 0 event, 0 điểm).
4. **Lỗi kiểu trả về trong `headless.gd` và `soak.gd`:**
   - *Mô tả lỗi:* Trong GDScript 4.7, hàm có kiểu trả về `-> Dictionary` không thể trả về `null` khi gặp tham số CLI sai (nó âm thầm tạo Dictionary rỗng), và `_init()` không được phép `return value`.
   - *Cách phát hiện:* Test `N-bad invalid night exits non-zero` và chạy thử `soak.gd`.
   - *Khắc phục:* Dùng sentinel `{"__error": true}` cho hàm trả về `Dictionary` và tách `_bad(); return` trong `_init()`.
5. **Lỗi gọi đồng bộ `OS.execute("powershell")` ngay giữa vòng lặp render của Benchmark (`p1_low_fps` tụt xuống 20.6 FPS):**
   - *Mô tả lỗi:* Ở lần đo đầu tiên của `src/bench.gd`, `ProcMem.peak_mb()` được gọi mỗi 2 giây bên trong `_process(delta)`. Trên Windows, mỗi lần spawn PowerShell để đọc `PeakWorkingSet64` tốn ~200 ms đồng bộ, tạo ra 15 frame spike làm `p1_low_fps` tụt xuống `20.6` dù `avg_fps` đạt `167.5`.
   - *Cách phát hiện:* Phân tích sự bất thường giữa `frame_ms_p95 = 10.0 ms` (~100 FPS) và `p1_low_fps = 20.6 FPS`.
   - *Khắc phục:* Vì `PeakWorkingSet64` được Windows Kernel theo dõi liên tục ở mức OS, chỉ đọc `ProcMem.peak_mb()` đúng một lần trong `_finish_bench()` sau khi kết thúc 30 giây đo. Kết quả `p1_low_fps` tăng vọt từ `20.6` lên **`62.2 FPS`** (vượt xa ngưỡng `>= 30 FPS`).

---

## 4. Harness nào giúp nhiều nhất

1. **`AGENTS.md` + `game.contract.json` (Single Source of Truth):** Ngăn chặn hoàn toàn việc AI tự bịa thêm CLI flags hoặc hardcode số liệu ở nhiều file khác nhau.
2. **`docs/notes/assumptions.md` và `docs/adr/ADR-003` & `ADR-004`:** Là "bộ nhớ dài hạn" cực kỳ hiệu quả giữa các phiên làm việc. Khi model thay đổi hoặc context được rút gọn, đọc lại ADR giúp nắm ngay quy ước góc bản đồ (`0°=+X, 90°=+Z`), đơn vị `fuel_units = fuel * 60`, và thứ tự ưu tiên terminal.
3. **`tests/run_tests.sh` kết hợp `tests/unit/run_unit.gd` & `run_unit_p4.gd`:** Cổng kiểm soát chất lượng tự động (280+ assertions) chạy trước mỗi lần commit.

---

## 5. Ước tính Token / Chi phí AI và Cách tiết kiệm Token

> **Lưu ý:** Số liệu dưới đây là **ước tính (estimate)** dựa trên độ dài ngữ cảnh, số lượt gọi công cụ và khối lượng mã nguồn/tài liệu qua 4 Phase, vì môi trường IDE không xuất trực tiếp hóa đơn token API theo từng lượt.

- **Ước tính tổng lượng token qua 4 Phase:**
  - *Input / Context tokens (đọc spec, code, log test):* ~350.000 – 450.000 tokens.
  - *Output tokens (viết code GDScript, tests, ADR, evidence, docs):* ~70.000 – 95.000 tokens.
  - *Ước tính chi phí quy đổi theo biểu giá API thương mại tương đương:* khoảng **\$2.50 – \$4.00 USD** cho toàn bộ chu kỳ 4 Phase.
- **Các kỹ thuật tiết kiệm token hiệu quả nhất đã áp dụng:**
  1. **Gộp nhiều thao tác độc lập vào cùng một lượt (Batch tool calls):** Đọc nhiều file spec/code hoặc sửa nhiều vị trí độc lập trong một turn thay vì gọi từng lệnh nhỏ lẻ (vì mỗi turn đều gửi lại toàn bộ lịch sử hội thoại).
  2. **Lọc đầu ra kiểm thử (`Select-String -Pattern 'FAIL|Results'`):** Không đổ toàn bộ hàng trăm dòng `PASS` hoặc file `.jsonl` dài hàng megabyte vào context; chỉ in dòng tổng kết và các dòng `FAIL`.
  3. **Ghi tóm tắt quyết định vào ADR/Status file:** Giúp các bước sau tra cứu nhanh mà không phải đọc lại toàn bộ lịch sử thảo luận.

---

## 6. Nếu làm lại từ đầu sẽ thay đổi điều gì

1. **Viết In-process Unit Test Runner (`run_unit.gd`) ngay từ Phase 1:** Ở Phase 1–2, mỗi bài test trong `run_tests.sh` gọi một tiến trình Godot mới, khá tốn thời gian khởi động trên Windows. Khi bổ sung `run_unit.gd` ở Phase 3–4, 226 assertions chạy trong chưa đầy 2 giây.
2. **Định nghĩa toàn bộ trạng thái bằng số nguyên (Integer Fixed-Point) ngay từ đầu:** Việc dùng `fuel_units` (1/60) và `ticks` nguyên ở Phase 3 đã chứng minh tính ưu việt tuyệt đối so với `float` về cả tính tất định lẫn việc tránh lỗi làm tròn ở tick biên.
3. **Tự động hóa kiểm tra parse GDScript trước khi chạy suite dài:** Một lệnh parse-check nhanh giúp phát hiện ngay lỗi kiểu tĩnh của GDScript 4.7 trước khi chạy benchmark hay soak test.
