# CREDITS — Đảo Đèn Lồng (Lantern Island)

## Tác giả & Kỹ sư phát triển
- **Hoàng Minh Huy** (`2A202603495`) — Thiết kế hệ thống, kiến trúc simulation tất định (`GameSim`), headless pipeline, 3D presentation, trợ năng và kiểm thử tự động.

## Game Engine & Runtime
- **Godot Engine 4.7.2 Stable** (`GL Compatibility` / `Jolt Physics`) — [https://godotengine.org](https://godotengine.org) — Giấy phép **MIT License**.

## Tài nguyên Đồ họa, Mesh, Vật liệu & Font (100% Procedural / Built-in)
- **3D Meshes & Materials:** Toàn bộ địa hình đảo (Đảo Bến, Đảo Cau, Đảo Chuông), đèn lồng, thanh nhiên liệu 3D, giấy rách, đom đóm, Bóng Mực, Gió Lạc, Bùa Gió và nhân vật Mây được khởi tạo **100% bằng mã nguồn GDScript** sử dụng các nguyên mẫu hình học tích hợp sẵn của Godot (`CylinderMesh`, `SphereMesh`, `CapsuleMesh`, `BoxMesh`, `StandardMaterial3D`, `OmniLight3D`, `DirectionalLight3D`, `WorldEnvironment`). Không sử dụng bất kỳ model 3D, texture hay asset thương mại bên ngoài nào.
- **Biểu tượng ứng dụng:** `icon.svg` — Biểu tượng mặc định của Godot Engine (MIT License).
- **Font chữ & Ký hiệu UI:** Sử dụng font hệ thống tích hợp sẵn của Godot 4.7 (OpenFont / FreeType — SIL Open Font License 1.1 / MIT) hỗ trợ đầy đủ tiếng Việt Unicode và ký hiệu cảnh báo `⚠`, `▲`, `←`, `→`, `↑`, `↓`.
- **Âm thanh:** Dự án ưu tiên hệ thống phụ đề & chỉ báo hình ảnh trực quan (Visual Indicators & Subtitles) đạt chuẩn trợ năng không phụ thuộc âm thanh; không sử dụng file âm thanh bên thứ ba.

## Công cụ AI & Harness hỗ trợ phát triển (AI SDLC)
- **AI Coding Agents:** Claude & Gemini (trong khuôn khổ bài thực hành AI SDLC Lab) hỗ trợ phân tích đặc tả (`PRD-0`, `TICKET-02`, `TICKET-03`, `TICKET-04`), viết ADR, sinh kịch bản kiểm thử hồi quy và tự động hóa kiểm thử.
- **Harness & Công cụ kiểm thử:**
  - `AGENTS.md`, `docs/notes/assumptions.md`, `docs/adr/ADR-003-lantern-fuel-and-dawn-survival.md`, `docs/adr/ADR-004-bench-soak-leaderboard.md`.
  - Git Bash, Python 3.12 (`tests/perf_bench.py`), GDScript headless unit test runner (`tests/unit/run_unit.gd`, `tests/unit/run_unit_p4.gd`).
