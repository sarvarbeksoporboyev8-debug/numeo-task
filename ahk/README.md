# Live Coding Session Runner

AutoHotkey v2 script that produces a believable 1–2 hour coding video by gradually typing code from snippet files into an empty VS Code project.

## Prerequisites

1. **AutoHotkey v2** — download from [https://www.autohotkey.com/v2/](https://www.autohotkey.com/v2/)
   - Run the installer, select "v2" when prompted
   - Verify: open a terminal and run `AutoHotkey32.exe --version` or check the Start Menu entry

2. **VS Code** installed and configured

3. **OBS Studio** (recommended) for screen recording
   - Optional: install a keystroke overlay plugin (e.g., [input-overlay](https://obsproject.com/forum/resources/input-overlay.552/)) so viewers can see keypresses

## Setup

1. Open `ahk/livecoding.ahk` in a text editor

2. Edit the `REPO_ROOT` path at the top of the file to point to your local clone:
   ```
   global REPO_ROOT := "C:\Users\YOU\numeo-task"
   ```

3. Verify `recording-project/` is empty (no files or folders visible)

4. Open VS Code **directly on the recording-project folder**:
   ```
   code recording-project
   ```
   This is what the viewer sees at timestamp 00:00 — an empty project.

5. Make sure the VS Code integrated terminal is closed before starting

## Running the Session

1. Double-click `livecoding.ahk` to load it (AHK icon appears in system tray)
2. Focus VS Code
3. Press **Ctrl + Alt + 0** to start the full session
4. The script runs nonstop through all 8 phases — no interaction needed

## Hotkeys

| Key | Action |
|-----|--------|
| `Ctrl+Alt+0` | Start full session |
| `Ctrl+Alt+Q` | Emergency exit (stops script immediately) |
| `Ctrl+Alt+P` | Pause / Resume |

## Session Phases

| Phase | Duration (approx) | What happens |
|-------|-------------------|--------------|
| 0 | 3–5 min | Creates folders and empty files via terminal |
| 1 | 10–15 min | Frontend index.tsx + App.tsx shell |
| 2 | 12–18 min | Backend server.ts skeleton |
| 3 | 15–20 min | Frontend state, useEffect, handlers |
| 4 | 15–20 min | Backend validation, transcribe/translate stubs |
| 5 | 12–18 min | Wires frontend API calls to backend socket |
| 6 | 15–20 min | CSS in 5 stages + JSX controls/results |
| 7 | 10–15 min | Fixes stale closure bug + backend error handling |

Total: ~90–130 minutes depending on typing speed settings.

## Tuning Duration

Edit the delay constants at the top of `livecoding.ahk`:

- `TYPE_MIN_DELAY` / `TYPE_MAX_DELAY` — per-character typing speed (ms)
- `PAUSE_SHORT` through `PAUSE_PHASE` — pauses between actions
- Increase all values by 1.5x to stretch the session closer to 2 hours

## Embedded Bugs (Fixed in Phase 7)

**Frontend (stale closure):** The `socket.on('translation')` handler in Phase 3 uses `setTranslations([data, ...translations])` which captures the initial empty array. Only the most recent translation ever appears. Fixed in Phase 7 with `setTranslations(prev => [data, ...prev])`.

**Backend (weak error handling):** The `transcribeAudio` and `translateText` functions in Phase 4 let raw axios errors propagate without logging or wrapping. Fixed in Phase 7 with try/catch blocks and structured error messages.

## Tips for Recording

- Set VS Code font size to 16–18px for readability
- Use a dark theme (e.g., One Dark Pro)
- Hide the Activity Bar and minimap for a cleaner look
- Start OBS recording before pressing Ctrl+Alt+0
- The keystroke overlay helps viewers follow along
