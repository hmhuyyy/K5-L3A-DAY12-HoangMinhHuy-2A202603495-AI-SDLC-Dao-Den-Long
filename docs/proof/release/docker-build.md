# Evidence — Task C: Docker Image (`dao-den-long:1.0.0`)

## 1. Thông tin Môi trường & Image Thực tế

- **Thời điểm kiểm tra:** `2026-11-20T23:51:01+07:00` (`2026-11-20T16:51:01Z`)
- **Docker Client:** Version `29.9.3`, API `1.56`, Go `go1.26.10`, Git commit `5457199`, `windows/amd64`, Context `desktop-linux`
- **Docker Server:** `Docker Desktop 4.99.0 (245822)`, Engine Version `29.9.3`, API `1.56`, Git commit `70efc0e`, `linux/amd64`, containerd `v2.4.2`, runc `1.5.2`
- **Image Tag:** `dao-den-long:1.0.0`
- **Image ID (Full SHA-256):** `sha256:f31e327cfa397c36faa79a3167da540bcc46fb5bb24d86c98b872fe813479780` (Short ID: `f31e327cfa39`)
- **Image Size:** `660,632,812 bytes` (`661 MB` Disk Usage / `211 MB` Content Size)
- **Dockerfile:** [Dockerfile](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/Dockerfile) (`ubuntu:24.04` + `Godot_v4.7.2-stable_linux.x86_64`)

---

## 2. Kết quả Thực thi các Lệnh Kiểm chứng & Exit Codes

| Lệnh đã chạy | Exit Code | Kết quả |
|---|---:|---|
| `docker version` | **`0`** | Client & Server `29.9.3` hoạt động bình thường |
| `docker run --rm hello-world` | **`0`** | `Hello from Docker!` |
| `docker build -t dao-den-long:1.0.0 .` | **`0`** | Build và đóng gói image `dao-den-long:1.0.0` (`f31e327cfa39`) thành công |
| `docker run --rm dao-den-long:1.0.0` | **`0`** | Chạy `bash tests/run_tests.sh` trong container: **`Results: 283 passed, 0 failed`** |

---

## 3. Log Thực tế của `docker version` và `docker build -t dao-den-long:1.0.0 .`

```text
Client:
 Version:           29.9.3
 API version:       1.56
 Go version:        go1.26.10
 Git commit:        5457199
 Built:             Tue Nov  3 21:46:10 2026
 OS/Arch:           windows/amd64
 Context:           desktop-linux

Server: Docker Desktop 4.99.0 (245822)
 Engine:
  Version:          29.9.3
  API version:      1.56 (minimum version 1.40)
  Go version:       go1.26.10
  Git commit:       70efc0e
  Built:            Tue Nov  3 21:41:42 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.4.2
  GitCommit:        b7a25261e029d68978bbf290df0a62fc819b3c51
 runc:
  Version:          1.5.2
  GitCommit:        v1.5.2-0-g29dd3dc2
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

ID=sha256:f31e327cfa397c36faa79a3167da540bcc46fb5bb24d86c98b872fe813479780 Created=2026-11-20T16:51:01.76963213Z Size=660632812
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
dao-den-long:1.0.0   f31e327cfa39        661MB          211MB
```

---

## 4. Log Đầy đủ của `docker run --rm dao-den-long:1.0.0` (`283 passed, 0 failed`, `exit code 0`)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

PASS  F1 5 lanterns in tick-0
PASS  F1 score=0 at tick0
PASS  F1 2 lines total (snapshot+end)
PASS  F2 determinism (byte-identical)
PASS  F3 mote_picked fires
PASS  F3 exactly 1 mote_picked
PASS  F4 deposit fires
PASS  F4 lantern_lit fires
PASS  F5 shade S1 starts at x=20
PASS  F5 shade moved closer after 60 ticks
PASS  F6 shade never enters safe zone
PASS  F12 no events at setup
PASS  F12 score=0 with lit lantern
PASS  F15 invalid scenario exits 2
PASS  F16 end record present
PASS  F16 end state=playing
PASS  F16 end ticks=30
PASS  F21 zero-tick = 2 lines
PASS  F21 no events in zero-tick
PASS  F11 game_over reason=dawn
PASS  F11 end state=lost
PASS  F20 snapshot cadence (4 snapshots in 30 ticks)
PASS  F7 pulse event fires
PASS  F7 shade state=stunned after pulse
PASS  F8 player_hit event fires
PASS  F8 drop ratio applied
PASS  F9 game_over reason=dawn_survived
PASS  F9 end state=won
PASS  F10 game_over reason=no_flames
PASS  F10 end state=lost
PASS  F14 non-increasing ticks exit 2
PASS  F13 move persisted (player moved by tick 4)
PASS  F19 jump rose above 0
PASS  F19 player lands back at Y=0
PASS  H3 fuel_drain event fires
PASS  H3 fuel_drain has lantern/shade
PASS  H3 lantern_out event fires
PASS  H3 snapshot shows drain state
PASS  H3 snapshot lantern has fuel/ever_lit/relit_count
PASS  N1 headless night=1 runs, snapshot night field
PASS  N1 end record present
PASS  N1 determinism (byte-identical)
PASS  N2 headless night=2 runs, snapshot night field
PASS  N2 end record present
PASS  N2 determinism (byte-identical)
PASS  N3 headless night=3 runs, snapshot night field
PASS  N3 end record present
PASS  N3 determinism (byte-identical)
PASS  N-bad invalid night exits non-zero
PASS  JSONL no BOM
PASS  JSONL LF only
PASS  UNIT runner exit code 0 (173 unit assertions passed, 0 failed)
PASS  UNIT-P4 runner exit code 0 (53 assertions passed, 0 failed)
PASS  P4-CLI --export-leaderboard exits 0
PASS  P4-CLI --export-leaderboard writes {"entries":...}
PASS  P4-CLI soak_cmd 2-night smoke exits 0
PASS  P4-CLI soak_cmd crashes=0

Results: 283 passed, 0 failed
```

---

## 5. Trạng thái
- **Status:** **DONE (PASS)**
