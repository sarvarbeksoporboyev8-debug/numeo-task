; ============================================================================
; livecoding.ahk — Option C gradual live-coding session runner
; AutoHotkey v2 — one-key nonstop execution
;
; Ctrl+Alt+0  → Start full session (~2 hours)
; Ctrl+Alt+Q  → Emergency exit
; Ctrl+Alt+P  → Pause / Resume
; ============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; CONFIGURATION — adjust these paths before recording
; ---------------------------------------------------------------------------
global REPO_ROOT      := "C:\Users\YOU\numeo-task"          ; <-- EDIT THIS
global SNIPPETS_DIR   := REPO_ROOT "\snippets"
global RECORDING_DIR  := REPO_ROOT "\recording-project"

; Typing speed range (milliseconds per character)
global TYPE_MIN_DELAY := 28
global TYPE_MAX_DELAY := 72

; Pause durations (milliseconds)
global PAUSE_SHORT    := 800
global PAUSE_MEDIUM   := 2500
global PAUSE_LONG     := 5000
global PAUSE_THINK    := 8000   ; "thinking" pause between phases
global PAUSE_PHASE    := 15000  ; long pause between major phases

; Session state
global IsPaused       := false
global IsRunning      := false

; ---------------------------------------------------------------------------
; HOTKEYS
; ---------------------------------------------------------------------------
^!0::StartSession()
^!q::ExitSession()
^!p::TogglePause()

; ---------------------------------------------------------------------------
; SAFETY CONTROLS
; ---------------------------------------------------------------------------
ExitSession() {
    global IsRunning
    IsRunning := false
    MsgBox("Session aborted.", "Live Coding", "Iconi")
    ExitApp()
}

TogglePause() {
    global IsPaused
    IsPaused := !IsPaused
    ToolTip(IsPaused ? "⏸ PAUSED — Ctrl+Alt+P to resume" : "▶ RESUMED")
    SetTimer(() => ToolTip(), -3000)
}

WaitIfPaused() {
    global IsPaused
    while IsPaused
        Sleep(200)
}

; ---------------------------------------------------------------------------
; CORE TYPING ENGINE
; ---------------------------------------------------------------------------
TypeHuman(text, minDelay := 0, maxDelay := 0) {
    global TYPE_MIN_DELAY, TYPE_MAX_DELAY
    if minDelay = 0
        minDelay := TYPE_MIN_DELAY
    if maxDelay = 0
        maxDelay := TYPE_MAX_DELAY

    loop parse text {
        WaitIfPaused()
        char := A_LoopField

        ; Handle special characters that need escaping in SendInput
        if char = "`n" {
            SendInput("{Enter}")
        } else if char = "`t" {
            SendInput("{Tab}")
        } else if char = "{" {
            SendInput("{{}") 
        } else if char = "}" {
            SendInput("{}}")
        } else if char = "^" {
            SendInput("{^}")
        } else if char = "!" {
            SendInput("{!}")
        } else if char = "+" {
            SendInput("{+}")
        } else if char = "#" {
            SendInput("{#}")
        } else {
            SendInput(char)
        }

        delay := Random(minDelay, maxDelay)
        ; Occasional micro-pause to simulate thinking mid-word
        if Random(1, 100) <= 5
            delay += Random(200, 600)
        Sleep(delay)
    }
}

TypeLine(text) {
    TypeHuman(text)
    SendInput("{Enter}")
    Sleep(Random(100, 300))
}

; ---------------------------------------------------------------------------
; VS CODE HELPERS
; ---------------------------------------------------------------------------
OpenFileViaQuickOpen(filename) {
    WaitIfPaused()
    SendInput("^p")
    Sleep(600)
    TypeHuman(filename, 20, 50)
    Sleep(500)
    SendInput("{Enter}")
    Sleep(1000)
}

SaveFile() {
    WaitIfPaused()
    SendInput("^s")
    Sleep(800)
}

OpenTerminal() {
    WaitIfPaused()
    SendInput("^``")
    Sleep(1200)
}

CloseTerminal() {
    WaitIfPaused()
    SendInput("^``")
    Sleep(600)
}

SelectAllContent() {
    SendInput("^a")
    Sleep(300)
}

DeleteSelection() {
    SendInput("{Delete}")
    Sleep(200)
}

GoToLine(lineNum) {
    WaitIfPaused()
    SendInput("^g")
    Sleep(500)
    TypeHuman(String(lineNum), 30, 60)
    Sleep(300)
    SendInput("{Enter}")
    Sleep(500)
}

GoToEndOfFile() {
    SendInput("^{End}")
    Sleep(400)
}

GoToStartOfFile() {
    SendInput("^{Home}")
    Sleep(400)
}

; Move cursor down N lines
CursorDown(n) {
    loop n {
        SendInput("{Down}")
        Sleep(Random(30, 80))
    }
}

; Move cursor up N lines
CursorUp(n) {
    loop n {
        SendInput("{Up}")
        Sleep(Random(30, 80))
    }
}

MoveToLineEnd() {
    SendInput("{End}")
    Sleep(100)
}

InsertNewLineBelow() {
    MoveToLineEnd()
    SendInput("{Enter}")
    Sleep(200)
}

; Select from current line down N lines
SelectLines(n) {
    SendInput("{Home}")
    loop n {
        SendInput("+{Down}")
        Sleep(50)
    }
    Sleep(200)
}

; ---------------------------------------------------------------------------
; SNIPPET READER
; ---------------------------------------------------------------------------
ReadSnippet(relativePath) {
    global SNIPPETS_DIR
    fullPath := SNIPPETS_DIR "\" relativePath
    if !FileExist(fullPath) {
        MsgBox("Snippet not found: " fullPath, "Error", "Icon!")
        return ""
    }
    return FileRead(fullPath)
}

; ---------------------------------------------------------------------------
; TERMINAL COMMAND TYPER — types a command in the integrated terminal
; ---------------------------------------------------------------------------
TerminalType(cmd) {
    WaitIfPaused()
    TypeHuman(cmd, 35, 85)
    Sleep(Random(300, 700))
    SendInput("{Enter}")
}

TerminalTypeAndWait(cmd, waitMs := 3000) {
    TerminalType(cmd)
    Sleep(waitMs)
}

; ---------------------------------------------------------------------------
; PHASE 0 — HUMAN SCAFFOLDING
; Create project structure from empty recording-project/ folder
; ---------------------------------------------------------------------------
Phase0_Scaffolding() {
    ToolTip("Phase 0: Project Scaffolding")

    OpenTerminal()
    Sleep(PAUSE_MEDIUM)

    ; Create directory structure — type each command slowly
    TerminalTypeAndWait("mkdir -p frontend/src", 2000)
    Sleep(PAUSE_SHORT)

    TerminalTypeAndWait("mkdir -p backend/src", 2000)
    Sleep(PAUSE_MEDIUM)

    ; Create empty files
    TerminalTypeAndWait("touch frontend/src/index.tsx", 1500)
    Sleep(PAUSE_SHORT)

    TerminalTypeAndWait("touch frontend/src/App.tsx", 1500)
    Sleep(PAUSE_SHORT)

    TerminalTypeAndWait("touch frontend/src/App.css", 1500)
    Sleep(PAUSE_MEDIUM)

    TerminalTypeAndWait("touch backend/src/server.ts", 1500)
    Sleep(PAUSE_SHORT)

    ; Brief pause to let explorer update
    Sleep(PAUSE_LONG)

    ; Clear terminal for clean look
    TerminalTypeAndWait("clear", 1000)

    CloseTerminal()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 1 — FRONTEND SKELETONS
; ---------------------------------------------------------------------------
Phase1_FrontendSkeletons() {
    ToolTip("Phase 1: Frontend Skeletons")

    ; --- index.tsx ---
    OpenFileViaQuickOpen("index.tsx")
    Sleep(PAUSE_MEDIUM)
    snippet := ReadSnippet("frontend\index\01-bootstrap.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; --- App.tsx: imports and shell ---
    OpenFileViaQuickOpen("App.tsx")
    Sleep(PAUSE_MEDIUM)
    snippet := ReadSnippet("frontend\App\01-imports-and-shell.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 2 — BACKEND SKELETON
; ---------------------------------------------------------------------------
Phase2_BackendSkeleton() {
    ToolTip("Phase 2: Backend Skeleton")

    OpenFileViaQuickOpen("server.ts")
    Sleep(PAUSE_MEDIUM)

    ; imports and app setup
    snippet := ReadSnippet("backend\server\01-imports-and-app.txt")
    TypeHuman(snippet)
    Sleep(PAUSE_MEDIUM)

    ; middleware and cors
    SendInput("{Enter}{Enter}")
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("backend\server\02-middleware-cors.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; route skeleton (placeholder)
    SendInput("{Enter}{Enter}")
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("backend\server\03-route-skeleton.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 3 — FRONTEND LOGIC + STATE
; ---------------------------------------------------------------------------
Phase3_FrontendLogic() {
    ToolTip("Phase 3: Frontend Logic + State")

    ; Revisit App.tsx — add state model inside component
    OpenFileViaQuickOpen("App.tsx")
    Sleep(PAUSE_MEDIUM)

    ; Navigate to inside the component (after the opening line of the function)
    GoToLine(12)
    Sleep(PAUSE_SHORT)
    InsertNewLineBelow()
    Sleep(PAUSE_SHORT)

    ; Type state + useEffect with the stale closure bug
    snippet := ReadSnippet("frontend\App\02-state-model.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; Add handlers
    SendInput("{Enter}{Enter}")
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("frontend\App\04-handlers-setup.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Add stub API call
    SendInput("{Enter}{Enter}")
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("frontend\App\05-api-call-stub.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 4 — BACKEND ROUTES + VALIDATION
; ---------------------------------------------------------------------------
Phase4_BackendRoutes() {
    ToolTip("Phase 4: Backend Routes + Validation")

    ; Revisit server.ts
    OpenFileViaQuickOpen("server.ts")
    Sleep(PAUSE_MEDIUM)

    ; Add validation / env debug after the app setup
    GoToLine(22)
    Sleep(PAUSE_SHORT)
    InsertNewLineBelow()
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("backend\server\04-validation.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; Add transcribe stub (weak error handling — the imperfection)
    GoToEndOfFile()
    Sleep(PAUSE_SHORT)
    SendInput("{Enter}{Enter}")
    snippet := ReadSnippet("backend\server\05-translate-stub.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Add translate function (also weak error handling)
    SendInput("{Enter}{Enter}")
    Sleep(PAUSE_SHORT)
    snippet := ReadSnippet("backend\server\06-translate-real.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 5 — API WIRING (frontend ↔ backend)
; ---------------------------------------------------------------------------
Phase5_ApiWiring() {
    ToolTip("Phase 5: API Wiring")

    ; Revisit App.tsx — replace stub with real API call
    OpenFileViaQuickOpen("App.tsx")
    Sleep(PAUSE_MEDIUM)

    ; Find and select the stub sendAudioToBackend
    SendInput("^h")  ; Find and Replace
    Sleep(800)
    TypeHuman("// TODO: implement actual socket emit", 20, 40)
    Sleep(500)
    SendInput("{Tab}")  ; move to replace field
    Sleep(300)
    TypeHuman("// real implementation below", 20, 40)
    Sleep(300)
    SendInput("{Enter}")  ; replace
    Sleep(500)
    SendInput("{Escape}")  ; close find/replace
    Sleep(PAUSE_MEDIUM)

    ; Now select the entire stub function and replace it
    ; Use Ctrl+H again for the whole stub replacement
    SendInput("^h")
    Sleep(800)
    ; Clear previous search
    SendInput("^a")
    Sleep(100)
    TypeHuman("const sendAudioToBackend = (audioBlob: Blob) => {", 20, 40)
    Sleep(300)
    SendInput("{Escape}")
    Sleep(500)

    ; Simpler approach: go to the stub function, select it, delete, type new
    SendInput("^g")
    Sleep(500)
    ; Find the stub — we know roughly where it is
    SendInput("{Escape}")
    Sleep(300)

    ; Use Ctrl+Shift+K to delete lines of the old stub, then type new
    ; First find it
    SendInput("^f")
    Sleep(500)
    TypeHuman("Would send audio blob", 20, 40)
    Sleep(500)
    SendInput("{Escape}")
    Sleep(300)

    ; Select the 4-line stub function
    SendInput("{Home}")
    CursorUp(1)
    SendInput("{Home}")
    SelectLines(5)
    DeleteSelection()
    Sleep(PAUSE_SHORT)

    ; Type the real implementation
    snippet := ReadSnippet("frontend\App\06-api-call-real.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Revisit server.ts — wire up the real socket handler
    OpenFileViaQuickOpen("server.ts")
    Sleep(PAUSE_MEDIUM)

    ; Find the placeholder route and replace it
    SendInput("^f")
    Sleep(500)
    TypeHuman("// TODO: implement transcription", 20, 40)
    Sleep(500)
    SendInput("{Escape}")
    Sleep(300)

    ; Select the placeholder block inside the audio handler
    SendInput("{Home}")
    SelectLines(5)
    DeleteSelection()
    Sleep(PAUSE_SHORT)

    ; Type the real wired-up handler + listen
    snippet := ReadSnippet("backend\server\08-listen.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)
}

; ---------------------------------------------------------------------------
; PHASE 6 — CSS STAGES
; ---------------------------------------------------------------------------
Phase6_CSS() {
    ToolTip("Phase 6: CSS Styling")

    OpenFileViaQuickOpen("App.css")
    Sleep(PAUSE_MEDIUM)

    ; Base CSS
    snippet := ReadSnippet("frontend\styles\01-base-css.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; Layout CSS
    SendInput("{Enter}{Enter}")
    snippet := ReadSnippet("frontend\styles\02-layout-css.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Form controls
    SendInput("{Enter}{Enter}")
    snippet := ReadSnippet("frontend\styles\03-form-controls.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; Results panel (buttons, loading)
    SendInput("{Enter}{Enter}")
    snippet := ReadSnippet("frontend\styles\04-results-panel.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Polish — translations section
    SendInput("{Enter}{Enter}")
    snippet := ReadSnippet("frontend\styles\05-polish.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_THINK)

    ; Now revisit App.tsx to add the JSX for controls and results
    OpenFileViaQuickOpen("App.tsx")
    Sleep(PAUSE_MEDIUM)

    ; Find the placeholder controls div
    SendInput("^f")
    Sleep(500)
    TypeHuman("Controls will go here", 20, 40)
    Sleep(500)
    SendInput("{Escape}")
    Sleep(300)

    ; Select the placeholder line and its parent div
    SendInput("{Home}")
    CursorUp(1)
    SendInput("{Home}")
    SelectLines(3)
    DeleteSelection()
    Sleep(PAUSE_SHORT)

    ; Type the real controls
    snippet := ReadSnippet("frontend\App\08-error-loading-states.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_MEDIUM)

    ; Add translations list before closing </div>
    ; Find the closing tags
    GoToEndOfFile()
    CursorUp(3)
    MoveToLineEnd()
    SendInput("{Enter}")
    Sleep(PAUSE_SHORT)

    snippet := ReadSnippet("frontend\App\07-render-results.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_PHASE)
}

; ---------------------------------------------------------------------------
; PHASE 7 — REFACTOR + POLISH (fix bugs)
; ---------------------------------------------------------------------------
Phase7_RefactorPolish() {
    ToolTip("Phase 7: Refactor + Polish")

    ; --- Fix frontend stale closure bug ---
    OpenFileViaQuickOpen("App.tsx")
    Sleep(PAUSE_MEDIUM)

    ; Find the buggy line
    SendInput("^f")
    Sleep(500)
    TypeHuman("setTranslations([data, ...translations])", 20, 40)
    Sleep(500)
    SendInput("{Escape}")
    Sleep(PAUSE_SHORT)

    ; Select the buggy translation handler (about 4 lines)
    SendInput("{Home}")
    CursorUp(1)
    SendInput("{Home}")
    SelectLines(5)
    DeleteSelection()
    Sleep(PAUSE_MEDIUM)

    ; Type the fixed version
    snippet := ReadSnippet("frontend\App\09-refactor-small.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; --- Fix backend weak error handling ---
    OpenFileViaQuickOpen("server.ts")
    Sleep(PAUSE_MEDIUM)

    ; Find the weak transcribeAudio function
    SendInput("^f")
    Sleep(500)
    TypeHuman("async function transcribeAudio", 20, 40)
    Sleep(500)
    SendInput("{Escape}")
    Sleep(PAUSE_SHORT)

    ; Select from this function through translateText (both functions)
    ; We need to select both weak functions and replace them
    SendInput("{Home}")
    ; Select a large block — both functions are roughly 50 lines total
    SelectLines(55)
    DeleteSelection()
    Sleep(PAUSE_MEDIUM)

    ; Type the improved versions with proper try/catch
    snippet := ReadSnippet("backend\server\07-error-handling.txt")
    TypeHuman(snippet)
    SaveFile()
    Sleep(PAUSE_LONG)

    ; Final save all
    SendInput("^k")
    Sleep(200)
    SendInput("s")  ; Save All (Ctrl+K S)
    Sleep(1000)

    ToolTip("Session complete!")
    SetTimer(() => ToolTip(), -5000)
}

; ---------------------------------------------------------------------------
; MAIN SESSION RUNNER
; ---------------------------------------------------------------------------
StartSession() {
    global IsRunning
    if IsRunning {
        ToolTip("Session already running!")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    IsRunning := true

    ; Brief countdown
    ToolTip("Starting in 3...")
    Sleep(1000)
    ToolTip("Starting in 2...")
    Sleep(1000)
    ToolTip("Starting in 1...")
    Sleep(1000)
    ToolTip("")

    ; Ensure VS Code is focused
    if WinExist("ahk_exe Code.exe")
        WinActivate()
    Sleep(1000)

    ; ---- PHASE 0: Scaffolding ----
    Phase0_Scaffolding()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 1: Frontend skeletons ----
    Phase1_FrontendSkeletons()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 2: Backend skeleton ----
    Phase2_BackendSkeleton()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 3: Frontend logic + state ----
    Phase3_FrontendLogic()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 4: Backend routes + validation ----
    Phase4_BackendRoutes()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 5: API wiring ----
    Phase5_ApiWiring()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 6: CSS stages ----
    Phase6_CSS()
    Sleep(PAUSE_PHASE)

    ; ---- PHASE 7: Refactor + polish ----
    Phase7_RefactorPolish()

    IsRunning := false
    MsgBox("Live coding session complete!", "Done", "Iconi T10")
}
