# Evidence — Task A: Windows Standalone Build (`build/windows/DaoDenLong.exe`)

## 1. Những gì đã kiểm tra
- **Godot executable & version:**
  - Binary: `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - Version: `4.7.2.stable.official.ed1daf0bf`
- **Godot Export Templates:**
  - Kiểm tra ban đầu tại `%APPDATA%\Godot\export_templates\4.7.2.stable` → thư mục chưa có template.
  - Đã tải và cài đặt chính xác bộ Windows Export Templates chính thức của Godot `4.7.2-stable` từ `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz` vào `C:\Users\Admin\AppData\Roaming\Godot\export_templates\4.7.2.stable\`:
    - `version.txt` (`13 bytes` — `4.7.2.stable`)
    - `windows_release_x86_64.exe` (`109,268,480 bytes`)
    - `windows_release_x86_64_console.exe` (`188,928 bytes`)
    - `windows_debug_x86_64.exe` (`103,176,704 bytes`)
    - `windows_debug_x86_64_console.exe` (`188,928 bytes`)
- **Export Preset ([export_presets.cfg](file:///c:/AI%20thực%20chiến/K5-L3-LAB-Day12-AI-SDLC/export_presets.cfg)):**
  - Đã tạo preset `"Windows Desktop"` (`x86_64`, `export_path="build/windows/DaoDenLong.exe"`, `include_filter="*.json"` để đóng gói `game.contract.json`, `exclude_filter="out/*,dist/*,build/*,tests/*"`).

## 2. Lệnh Export đã chạy & Kết quả

```powershell
& "C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Windows Desktop" build/windows/DaoDenLong.exe
```

- **Exit code:** **`0`** (`[ DONE ] savepack — 102 steps`).
- **Artifacts tạo ra trên đĩa:**
  | File | Đường dẫn | Dung lượng (Bytes) | Mô tả |
  |---|---|---:|---|
  | `DaoDenLong.exe` | `build/windows/DaoDenLong.exe` | `109,268,480` (~104.2 MB) | Windows x86_64 standalone executable |
  | `DaoDenLong.pck` | `build/windows/DaoDenLong.pck` | `166,612` (~162.7 KB) | Resource pack chứa toàn bộ `.gdc`, `GameScene.scn`, `game.contract.json`, `project.binary`, `.ctex` |
  | `DaoDenLong-v1.0.0-win64.zip` | `build/DaoDenLong-v1.0.0-win64.zip` | `38,224,616` (~36.45 MB) | Gói ZIP phân phối chứa `DaoDenLong.exe` + `DaoDenLong.pck` |

## 3. Kiểm thử Thực thi Độc lập (Từ bên ngoài thư mục dự án — `$env:TEMP`)

Đã chuyển thư mục làm việc sang `$env:TEMP` (`C:\Users\Admin\AppData\Local\Temp`) để đảm bảo `DaoDenLong.exe` chạy hoàn toàn từ `DaoDenLong.pck` đi kèm mà không phụ thuộc thư mục source:

1. **Chạy thử chế độ GUI 3D (`1280×720` Windowed OpenGL):**
   ```powershell
   Push-Location "$env:TEMP"
   Start-Process -FilePath "C:/AI thực chiến/K5-L3-LAB-Day12-AI-SDLC/build/windows/DaoDenLong.exe" -ArgumentList "--quit-after","30" -Wait -PassThru
   ```
   → **Exit code:** **`0`** (`standalone_gui_exit=0`).
2. **Chạy thử chế độ CLI (`--export-leaderboard`):**
   ```powershell
   Start-Process -FilePath "C:/AI thực chiến/K5-L3-LAB-Day12-AI-SDLC/build/windows/DaoDenLong.exe" -ArgumentList "--headless","--","--export-leaderboard","$env:TEMP/lb_standalone.json" -Wait -PassThru
   ```
   → **Exit code:** **`0`** (`standalone_cli_exit=0`), xuất file JSON hợp lệ `{"entries": [...]}`.

## 4. Trạng thái
- **Status:** **DONE (PASS)**
