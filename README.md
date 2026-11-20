# Đảo Đèn Lồng (Lantern Island)

Game 3D góc nhìn thứ ba trong Godot 4.7. Mây, người giữ đèn nhỏ tuổi, gom đom đóm để thắp lại 5 Đèn Lồng Lớn trên đảo giữa biển mây, đồng thời né Bóng Mực trong sương đen.

> Phase 1 · AI SDLC Lab · Cá nhân: Hoàng Minh Huy — 2A202603495

## Cài đặt và chạy (3 lệnh)

```bash
# 1. Clone
git clone https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long.git
cd K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long

# 2. Chạy game (có giao diện)
godot --path .

# 3. Chạy headless (Test Contract)
godot --headless --path . --script res://src/headless.gd -- --seed 42 --night 1 --ticks 300 --out out/result.jsonl
```

> Yêu cầu: Godot 4.7.x. Tải tại https://godotengine.org/download. Không cần bước build.

## Điều khiển

| Phím | Hành động |
|---|---|
| W/A/S/D hoặc mũi tên | Di chuyển |
| Chuột | Xoay camera |
| Space | Nhảy |
| E | Tương tác (nạp ánh sáng vào đèn lồng khi đứng gần) |
| Q | Tỏa sáng (xua Bóng Mực, tốn 1 đom đóm) |
| R | Chơi lại sau khi thắng/thua |

## Cách tính điểm

| Sự kiện | Điểm |
|---|---|
| Nhặt 1 đom đóm | +10 |
| Thắp 1 đèn lồng | +100 |
| Xua 1 Bóng Mực (pulse) | +20 |
| Thắng: mỗi giây còn lại | +5 |
| Thắng: mỗi ngọn lửa (máu) còn lại | +50 |

Thắng khi thắp đủ 5 đèn. Thua khi hết máu (flames = 0) hoặc hết giờ (dawn).

## Chạy test

```bash
bash tests/run_tests.sh
```

22 kịch bản kiểm tra: snapshot tick-0, tính tất định, nhặt đom đóm, nạp đèn, Bóng Mực đuổi, vùng an toàn, không-event-khi-setup, JSON sai exit 2, dawn loss, snapshot cadence, v.v.

## Headless (Test Contract v1.0)

```bash
godot --headless --path . --script res://src/headless.gd -- \
  --seed 42 --night 1 --ticks 300 --out out/result.jsonl \
  [--scenario scenarios/my.json] [--inputs inputs/my.json] [--snapshot-every 10]
```

Output là JSONL tới file `--out`, đúng theo Test Contract v1.0 (3 loại record: `snapshot`, `event`, `end`). Exit 0 khi thành công, 2 khi scenario/inputs sai định dạng.

Bảng khai báo tuning nằm ở `game.contract.json` (gốc repo) — đây là nguồn sự thật duy nhất cho mọi con số game.

## Kiến trúc

```
src/
  core/        Logic game thuần, không phụ thuộc hiển thị (GameSim, Config, Entities, RNG, InputState, EventBus)
  headless/    Pipeline headless: HeadlessRunner, ScenarioLoader, InputsLoader, JsonlWriter
  headless.gd  Entrypoint mỏng cho chế độ headless
  gameplay/    Scene 3D — chỉ đọc trạng thái từ GameSim, không chứa logic
```

Cùng `GameSim` dùng cho cả 3D và headless → đảm bảo tính tất định và nhất quán.

## Sáng tạo của tôi

(Phase 1 tập trung làm lõi đúng. Sáng tạo nhỏ sẽ thêm ở phase sau, đảm bảo không đổi đầu ra headless.)

## Tài liệu

- [GUIDE.md](GUIDE.md) · [CHECKPOINTS.md](CHECKPOINTS.md) · [RULES.md](RULES.md) · [RUBRIC.md](RUBRIC.md) · [SUBMISSION.md](SUBMISSION.md)
- [docs/spec/PRD-0.md](docs/spec/PRD-0.md) — PRD-0 + Test Contract v1.0
- [docs/notes/assumptions.md](docs/notes/assumptions.md) — giả định thiết kế
- [AGENTS.md](AGENTS.md) — harness cho AI agent
