// sfpad: LOGGING-ONLY probe of the game's SDL3 or XInput controller calls. It changes no input.
//
// The active sdl.hdll or directx.hdll imports controller functions through an import address table.
// install() swaps the table entries for a handful of gamepad/joystick functions with wrappers that call the
// real function unchanged and log what the game reads (new buttons/axes, button edges, event types).
// No code is detoured and no instructions are decoded. uninstall() puts the original pointers back.
//
// Output: controller_helper_log.txt in the game folder (capped at 1 MB).
#define HL_NAME(n) sfpad_##n
#include <hl.h>
#undef _GUID
#define NOMINMAX
#include <windows.h>
#include <xinput.h>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <cstdint>

namespace {

using std::uint8_t; using std::int16_t; using std::uint32_t;

// ---- SDL3 signatures (SDL_oldnames-free, plain C ABI) ----
using PollEventFn = bool(*)(void* event);
using GamepadButtonFn = bool(*)(void* gamepad, int button);
using GamepadAxisFn = int16_t(*)(void* gamepad, int axis);
using JoyButtonFn = bool(*)(void* joystick, int button);
using JoyAxisFn = int16_t(*)(void* joystick, int axis);
using JoyHatFn = uint8_t(*)(void* joystick, int hat);
using XInputStateFn = DWORD(WINAPI*)(DWORD, XINPUT_STATE*);

PollEventFn realPoll = nullptr;
GamepadButtonFn realGpButton = nullptr;
GamepadAxisFn realGpAxis = nullptr;
JoyButtonFn realJoyButton = nullptr;
JoyAxisFn realJoyAxis = nullptr;
JoyHatFn realJoyHat = nullptr;
XInputStateFn realXInputState = nullptr;

SRWLOCK lockLog = SRWLOCK_INIT;
SRWLOCK lockControl = SRWLOCK_INIT;
HANDLE logFile = INVALID_HANDLE_VALUE;
ULONGLONG startTick = 0;
long long logged = 0;
constexpr long long LOG_CAP = 1024 * 1024;
bool installed = false;
HMODULE patchedModule = nullptr;
int backend = 0; // 1 SDL3/sdl.hdll, 2 XInput/directx.hdll
long long callsXInput = 0;
XINPUT_GAMEPAD lastXInput[4] = {};
bool seenXInput[4] = {};
struct Patch { void** slot; void* original; void* wrapper; };
Patch patches[32] = {};
int patchCount = 0;
#ifdef SFPAD_TEST
bool failWrites = false;
#endif

// ---- counters / change tracking (all guarded by lockLog) ----
long long callsPoll = 0, callsGpButton = 0, callsGpAxis = 0, callsJoyButton = 0, callsJoyAxis = 0, callsJoyHat = 0;
long long eventsGamepad = 0, eventsJoystick = 0;
uint32_t seenGpButtons = 0, seenGpAxes = 0, seenJoyButtons = 0, seenJoyAxes = 0;
constexpr int SLOTS = 8;
void* gpSlot[SLOTS] = {}; void* joySlot[SLOTS] = {};
bool gpDown[SLOTS][32] = {}; int gpAxisBucket[SLOTS][8] = {};
bool joyDown[SLOTS][32] = {}; int joyAxisBucket[SLOTS][16] = {};
uint8_t joyHatLast[SLOTS][4] = {};
uint32_t eventDevices[SLOTS] = {};
int eventAxisBucket[2][SLOTS][16] = {};
uint32_t seenEventTypes[64] = {}; int seenEventCount = 0;

const char* gpButtonName(int b) {
    static const char* n[] = {"South(A)","East(B)","West(X)","North(Y)","Back","Guide","Start","LeftStick","RightStick",
        "LeftShoulder(LB)","RightShoulder(RB)","DpadUp","DpadDown","DpadLeft","DpadRight","Misc1","Paddle1","Paddle2","Paddle3","Paddle4","Touchpad"};
    return b >= 0 && b < (int)(sizeof(n) / sizeof(n[0])) ? n[b] : "?";
}
const char* gpAxisName(int a) {
    static const char* n[] = {"LeftX","LeftY","RightX","RightY","LeftTrigger(LT)","RightTrigger(RT)"};
    return a >= 0 && a < 6 ? n[a] : "?";
}

bool openLog() {
    if (logFile != INVALID_HANDLE_VALUE) CloseHandle(logFile);
    logFile = CreateFileW(L"controller_helper_log.txt", GENERIC_WRITE, FILE_SHARE_READ, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    startTick = GetTickCount64();
    logged = 0;
    return logFile != INVALID_HANDLE_VALUE;
}
// Caller holds lockLog.
void line(const char* fmt, ...) {
    if (logFile == INVALID_HANDLE_VALUE || logged >= LOG_CAP) return;
    char buf[320];
    int n = snprintf(buf, sizeof(buf), "%8llu ms  ", GetTickCount64() - startTick);
    va_list ap; va_start(ap, fmt);
    int m = vsnprintf(buf + n, sizeof(buf) - n - 2, fmt, ap);
    va_end(ap);
    if (m < 0) return;
    n += m; if (n > (int)sizeof(buf) - 2) n = (int)sizeof(buf) - 2;
    buf[n++] = '\n';
    DWORD written = 0;
    DWORD count = static_cast<DWORD>((LOG_CAP - logged < n) ? LOG_CAP - logged : n);
    WriteFile(logFile, buf, count, &written, nullptr);
    logged += written;
}
int slotFor(void** table, void* key) {
    if (!key) return -1;
    for (int i = 0; i < SLOTS; ++i) if (table[i] == key) return i;
    for (int i = 0; i < SLOTS; ++i) if (!table[i]) { table[i] = key; return i; }
    return -1; // Extra controllers must not corrupt another device's history.
}
int eventSlot(uint32_t id) {
    if (!id) return -1;
    for (int i = 0; i < SLOTS; ++i) if (eventDevices[i] == id) return i;
    for (int i = 0; i < SLOTS; ++i) if (!eventDevices[i]) { eventDevices[i] = id; return i; }
    return -1;
}
void resetSession() {
    callsPoll = callsGpButton = callsGpAxis = callsJoyButton = callsJoyAxis = callsJoyHat = 0;
    eventsGamepad = eventsJoystick = 0;
    callsXInput = 0;
    std::memset(lastXInput, 0, sizeof(lastXInput));std::memset(seenXInput, 0, sizeof(seenXInput));
    seenGpButtons = seenGpAxes = seenJoyButtons = seenJoyAxes = 0; seenEventCount = 0;
    std::memset(gpSlot, 0, sizeof(gpSlot)); std::memset(joySlot, 0, sizeof(joySlot));
    std::memset(gpDown, 0, sizeof(gpDown)); std::memset(joyDown, 0, sizeof(joyDown));
    std::memset(gpAxisBucket, 0, sizeof(gpAxisBucket)); std::memset(joyAxisBucket, 0, sizeof(joyAxisBucket));
    std::memset(joyHatLast, 0, sizeof(joyHatLast));
    std::memset(eventDevices, 0, sizeof(eventDevices)); std::memset(eventAxisBucket, 0, sizeof(eventAxisBucket));
}
int bucket(int value, int threshold) { return value > threshold ? 1 : (value < -threshold ? -1 : 0); }

// ---- wrappers: call the real function first, never alter its result ----
bool wPoll(void* ev) {
    bool r = realPoll(ev);
    if (!r || !ev) { AcquireSRWLockExclusive(&lockLog); ++callsPoll; ReleaseSRWLockExclusive(&lockLog); return r; }
    const uint8_t* p = static_cast<const uint8_t*>(ev);
    uint32_t type; std::memcpy(&type, p, 4);
    bool pad = (type >= 0x650 && type <= 0x65F), joy = (type >= 0x600 && type <= 0x60F);
    AcquireSRWLockExclusive(&lockLog);
    ++callsPoll;
    if (pad || joy) {
        if (pad) ++eventsGamepad; else ++eventsJoystick;
        bool known = false;
        for (int i = 0; i < seenEventCount; ++i) if (seenEventTypes[i] == type) known = true;
        if (!known && seenEventCount < 64) { seenEventTypes[seenEventCount++] = type; line("EVENT type 0x%X first seen (%s)", type, pad ? "gamepad" : "joystick"); }
        uint32_t which; std::memcpy(&which, p + 16, 4);
        if (type == 0x651 || type == 0x652) line("EVENT gamepad button %s %s (which=%u)", gpButtonName(p[20]), p[21] ? "DOWN" : "UP", which);
        else if (type == 0x603 || type == 0x604) line("EVENT joystick button %u %s (which=%u)", p[20], p[21] ? "DOWN" : "UP", which);
        else if (type == 0x650 || type == 0x600) {
            int16_t v; std::memcpy(&v, p + 24, 2);
            int axis = p[20];
            int slot = eventSlot(which); int b = bucket(v, 16000);
            if (slot >= 0 && axis < (pad ? 6 : 16) && eventAxisBucket[pad ? 1 : 0][slot][axis] != b) {
                eventAxisBucket[pad ? 1 : 0][slot][axis] = b;
                line("EVENT %s axis %d -> %d (value=%d which=%u)", pad ? "gamepad" : "joystick", axis, b, v, which);
            }
        } else if (type == 0x602) {
            line("EVENT joystick hat %u -> 0x%X (which=%u)", p[20], p[21], which);
        }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}
bool wGpButton(void* gp, int button) {
    bool r = realGpButton(gp, button);
    AcquireSRWLockExclusive(&lockLog);
    ++callsGpButton;
    if (button >= 0 && button < 32) {
        int s = slotFor(gpSlot, gp);
        if (!(seenGpButtons & (1u << button))) { seenGpButtons |= 1u << button; line("POLL gamepad button %s read for the first time", gpButtonName(button)); }
        if (s >= 0 && gpDown[s][button] != r) { gpDown[s][button] = r; line("POLL gamepad[%d] button %s %s", s, gpButtonName(button), r ? "DOWN" : "UP"); }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}
int16_t wGpAxis(void* gp, int axis) {
    int16_t r = realGpAxis(gp, axis);
    AcquireSRWLockExclusive(&lockLog);
    ++callsGpAxis;
    if (axis >= 0 && axis < 8) {
        int s = slotFor(gpSlot, gp);
        if (!(seenGpAxes & (1u << axis))) { seenGpAxes |= 1u << axis; line("POLL gamepad axis %s read for the first time", gpAxisName(axis)); }
        int b = bucket(axis >= 4 ? r / 2 : r, axis >= 4 ? 8000 : 16000);
        if (s >= 0 && gpAxisBucket[s][axis] != b) { gpAxisBucket[s][axis] = b; line("POLL gamepad[%d] axis %s -> %d (value %d)", s, gpAxisName(axis), b, r); }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}
bool wJoyButton(void* joy, int button) {
    bool r = realJoyButton(joy, button);
    AcquireSRWLockExclusive(&lockLog);
    ++callsJoyButton;
    if (button >= 0 && button < 32) {
        int s = slotFor(joySlot, joy);
        if (!(seenJoyButtons & (1u << button))) { seenJoyButtons |= 1u << button; line("POLL joystick button %d read for the first time", button); }
        if (s >= 0 && joyDown[s][button] != r) { joyDown[s][button] = r; line("POLL joystick[%d] button %d %s", s, button, r ? "DOWN" : "UP"); }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}
int16_t wJoyAxis(void* joy, int axis) {
    int16_t r = realJoyAxis(joy, axis);
    AcquireSRWLockExclusive(&lockLog);
    ++callsJoyAxis;
    if (axis >= 0 && axis < 16) {
        int s = slotFor(joySlot, joy);
        if (!(seenJoyAxes & (1u << axis))) { seenJoyAxes |= 1u << axis; line("POLL joystick axis %d read for the first time", axis); }
        int b = bucket(r, 16000);
        if (s >= 0 && joyAxisBucket[s][axis] != b) { joyAxisBucket[s][axis] = b; line("POLL joystick[%d] axis %d -> %d (value %d)", s, axis, b, r); }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}
uint8_t wJoyHat(void* joy, int hat) {
    uint8_t r = realJoyHat(joy, hat);
    AcquireSRWLockExclusive(&lockLog);
    ++callsJoyHat;
    if (hat >= 0 && hat < 4) {
        int s = slotFor(joySlot, joy);
        if (s >= 0 && joyHatLast[s][hat] != r) { joyHatLast[s][hat] = r; line("POLL joystick[%d] hat %d -> 0x%X", s, hat, r); }
    }
    ReleaseSRWLockExclusive(&lockLog);
    return r;
}

DWORD WINAPI wXInputState(DWORD player, XINPUT_STATE* state) {
    DWORD result = realXInputState(player, state);
    AcquireSRWLockExclusive(&lockLog);
    ++callsXInput;
    if (result == ERROR_SUCCESS && state && player < 4) {
        const auto& g = state->Gamepad; const auto& old = lastXInput[player];
        bool changed = !seenXInput[player] || g.wButtons != old.wButtons
            || (g.bLeftTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD) != (old.bLeftTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD)
            || (g.bRightTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD) != (old.bRightTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD)
            || bucket(g.sThumbLX,16000) != bucket(old.sThumbLX,16000) || bucket(g.sThumbLY,16000) != bucket(old.sThumbLY,16000)
            || bucket(g.sThumbRX,16000) != bucket(old.sThumbRX,16000) || bucket(g.sThumbRY,16000) != bucket(old.sThumbRY,16000);
        if (changed) line("XINPUT player=%lu buttons=0x%04X LT=%u RT=%u left=(%d,%d) right=(%d,%d)",
            player,g.wButtons,g.bLeftTrigger,g.bRightTrigger,g.sThumbLX,g.sThumbLY,g.sThumbRX,g.sThumbRY);
        lastXInput[player] = g; seenXInput[player] = true;
    }
    ReleaseSRWLockExclusive(&lockLog);
    return result; // Never mutate the caller's state, packet number or error code.
}

// ---- import-table patching (loaded SDL or DirectX input module only) ----
struct Target { const char* name; void** real; void* wrapper; };
Target targets[] = {
    {"SDL_PollEvent", reinterpret_cast<void**>(&realPoll), reinterpret_cast<void*>(&wPoll)},
    {"SDL_GetGamepadButton", reinterpret_cast<void**>(&realGpButton), reinterpret_cast<void*>(&wGpButton)},
    {"SDL_GetGamepadAxis", reinterpret_cast<void**>(&realGpAxis), reinterpret_cast<void*>(&wGpAxis)},
    {"SDL_GetJoystickButton", reinterpret_cast<void**>(&realJoyButton), reinterpret_cast<void*>(&wJoyButton)},
    {"SDL_GetJoystickAxis", reinterpret_cast<void**>(&realJoyAxis), reinterpret_cast<void*>(&wJoyAxis)},
    {"SDL_GetJoystickHat", reinterpret_cast<void**>(&realJoyHat), reinterpret_cast<void*>(&wJoyHat)},
    {"XInputGetState", reinterpret_cast<void**>(&realXInputState), reinterpret_cast<void*>(&wXInputState)},
};
constexpr int TARGETS = sizeof(targets) / sizeof(targets[0]);

bool writeThunk(void** slot, void* expected, void* value) {
#ifdef SFPAD_TEST
    if (failWrites) return false;
#endif
    DWORD old = 0;
    if (!VirtualProtect(slot, sizeof(void*), PAGE_READWRITE, &old)) return false;
    bool changed = InterlockedCompareExchangePointer(slot, value, expected) == expected;
    DWORD ignore = 0; VirtualProtect(slot, sizeof(void*), old, &ignore);
    return changed;
}
// mode 0: patch in wrappers, mode 1: restore originals. Returns number of entries changed or negative on failure.
int walkImports(HMODULE module, bool restore) {
    if (restore) {
        int remaining = 0, restored = 0;
        for (int i = 0; i < patchCount; ++i) {
            auto p = patches[i];
            if (*p.slot == p.original || writeThunk(p.slot, p.wrapper, p.original)) ++restored;
            else patches[remaining++] = p;
        }
        patchCount = remaining;
        return remaining ? -7 : restored;
    }
    auto base = reinterpret_cast<uint8_t*>(module);
    auto dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE || dos->e_lfanew < int(sizeof(*dos))) return -2;
    auto nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE || nt->OptionalHeader.Magic != IMAGE_NT_OPTIONAL_HDR64_MAGIC) return -2;
    auto& dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!dir.VirtualAddress) return -3;
    int changed = 0;
    for (auto desc = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(base + dir.VirtualAddress); desc->Name; ++desc) {
        const char* library = reinterpret_cast<const char*>(base + desc->Name);
        if (_stricmp(library, "SDL3.dll") != 0 && _strnicmp(library, "XINPUT", 6) != 0) continue;
        // FirstThunk contains absolute function pointers in a loaded image, not names.
        if (!desc->OriginalFirstThunk || !desc->FirstThunk) return -3;
        auto names = reinterpret_cast<IMAGE_THUNK_DATA*>(base + desc->OriginalFirstThunk);
        auto thunks = reinterpret_cast<IMAGE_THUNK_DATA*>(base + desc->FirstThunk);
        for (; names->u1.AddressOfData; ++names, ++thunks) {
            if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal)) continue;
            auto byName = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(base + names->u1.AddressOfData);
            for (int i = 0; i < TARGETS; ++i) {
                if (std::strcmp(byName->Name, targets[i].name) != 0) continue;
                void** slot = reinterpret_cast<void**>(&thunks->u1.Function);
                if (*slot != targets[i].wrapper) {
                    if (patchCount >= int(sizeof(patches) / sizeof(patches[0]))) return -6;
                    if (*targets[i].real && *targets[i].real != *slot) return -6;
                    if (!*targets[i].real) *targets[i].real = *slot;
                    if (!writeThunk(slot, *targets[i].real, targets[i].wrapper)) return -6;
                    patches[patchCount++] = {slot, *targets[i].real, targets[i].wrapper};
                    ++changed;
                    AcquireSRWLockExclusive(&lockLog); line("IMPORT %s patched", targets[i].name); ReleaseSRWLockExclusive(&lockLog);
                }
            }
        }
    }
    return changed;
}

} // namespace

// Returns import count (SDL=6, XInput=1), -1 no supported loaded input module,
// -2/-3 unreadable module, -4 log open failed, -5 pin failed, -6 patch failed, -7 restore failed.
HL_PRIM int HL_NAME(pad_install)() {
    AcquireSRWLockExclusive(&lockControl);
    if (installed) { int n = patchCount; ReleaseSRWLockExclusive(&lockControl); return n; }
    HMODULE module = GetModuleHandleW(L"directx.hdll");
    backend = 2;
    if (!module) { module = GetModuleHandleW(L"sdl.hdll"); backend = 1; }
    if (!module) { ReleaseSRWLockExclusive(&lockControl); return -1; }
    // Pin this DLL: sdl.hdll will hold pointers into it for as long as it is patched.
    HMODULE pinned = nullptr;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN, reinterpret_cast<LPCWSTR>(&wPoll), &pinned)) {
        ReleaseSRWLockExclusive(&lockControl); return -5;
    }
    AcquireSRWLockExclusive(&lockLog);
    resetSession();
    bool opened = openLog();
    line("---- sfpad 0.3 logging started (input unchanged) ----");
    line("backend: %s",backend == 2 ? "XInput in directx.hdll" : "SDL3 in sdl.hdll");
    ReleaseSRWLockExclusive(&lockLog);
    if (!opened) { ReleaseSRWLockExclusive(&lockControl); return -4; }
    int n = walkImports(module, false);
    if (n < 0 && walkImports(module, true) < 0) n = -7;
    installed = patchCount > 0; patchedModule = installed ? module : nullptr;
    AcquireSRWLockExclusive(&lockLog);
    line("install: patched %d controller import(s), backend=%d (result %d)", patchCount, backend, n);
    if (!installed) { CloseHandle(logFile); logFile = INVALID_HANDLE_VALUE; }
    ReleaseSRWLockExclusive(&lockLog);
    ReleaseSRWLockExclusive(&lockControl); return n;
}
DEFINE_PRIM(_I32, pad_install, _NO_ARG);

// Restores the original import pointers. Returns the number restored.
HL_PRIM int HL_NAME(pad_uninstall)() {
    AcquireSRWLockExclusive(&lockControl);
    if (!installed || !patchedModule) { ReleaseSRWLockExclusive(&lockControl); return 0; }
    int n = walkImports(patchedModule, true);
    installed = patchCount > 0;
    AcquireSRWLockExclusive(&lockLog);
    if (logged >= LOG_CAP) {
        LARGE_INTEGER tail; tail.QuadPart = LOG_CAP - 1024;
        SetFilePointerEx(logFile, tail, nullptr, FILE_BEGIN); logged = LOG_CAP - 1024;
        line("-- log cap reached; reserving tail for final counters --");
    }
    line("uninstall: restored %d import(s). calls: poll=%lld gpButton=%lld gpAxis=%lld joyButton=%lld joyAxis=%lld joyHat=%lld; events: gamepad=%lld joystick=%lld",
        n, callsPoll, callsGpButton, callsGpAxis, callsJoyButton, callsJoyAxis, callsJoyHat, eventsGamepad, eventsJoystick);
    line("XInputGetState calls=%lld",callsXInput);
    if (n < 0) line("STOP FAILED: %d import(s) remain; retry Stop", patchCount);
    if (!installed) {
        SetEndOfFile(logFile); CloseHandle(logFile); logFile = INVALID_HANDLE_VALUE; patchedModule = nullptr;
    }
    ReleaseSRWLockExclusive(&lockLog);
    ReleaseSRWLockExclusive(&lockControl); return n;
}
DEFINE_PRIM(_I32, pad_uninstall, _NO_ARG);

// Read-only status: safe to poll without filling the log.
HL_PRIM int HL_NAME(pad_status)() {
    AcquireSRWLockShared(&lockControl); int n = installed ? 1 : 0;
    ReleaseSRWLockShared(&lockControl); return n;
}
DEFINE_PRIM(_I32, pad_status, _NO_ARG);

// 0=imports, 1=PollEvent, 2/3=gamepad button/axis, 4/5/6=joystick
// button/axis/hat, 7/8=gamepad/joystick events. No file IO.
HL_PRIM int HL_NAME(pad_count)(int index) {
    if (index == 0) {
        AcquireSRWLockShared(&lockControl); int n = patchCount; ReleaseSRWLockShared(&lockControl); return n;
    }
    AcquireSRWLockShared(&lockLog);
    long long n = -1;
    switch (index) {
        case 1: n = callsPoll; break; case 2: n = callsGpButton; break; case 3: n = callsGpAxis; break;
        case 4: n = callsJoyButton; break; case 5: n = callsJoyAxis; break; case 6: n = callsJoyHat; break;
        case 7: n = eventsGamepad; break; case 8: n = eventsJoystick; break;
        case 9: n = callsXInput; break;
    }
    ReleaseSRWLockShared(&lockLog); return n > INT_MAX ? INT_MAX : int(n);
}
DEFINE_PRIM(_I32, pad_count, _I32);

HL_PRIM int HL_NAME(pad_backend)() {
    AcquireSRWLockShared(&lockControl); int n = backend; ReleaseSRWLockShared(&lockControl); return n;
}
DEFINE_PRIM(_I32, pad_backend, _NO_ARG);
