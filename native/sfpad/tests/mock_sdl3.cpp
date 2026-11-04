#include <cstdint>
#include <cstring>
#define API extern "C" __declspec(dllexport)
static uint8_t eventBytes[128] = {};
static bool pollResult = true;
API void mock_event(const void* bytes, bool result) { std::memcpy(eventBytes, bytes, 128); pollResult = result; }
API bool SDL_PollEvent(void* event) { if (pollResult && event) std::memcpy(event, eventBytes, 128); return pollResult; }
API bool SDL_GetGamepadButton(void*, int button) { return (button & 1) != 0; }
API int16_t SDL_GetGamepadAxis(void*, int axis) { return axis & 1 ? 32767 : -32768; }
API bool SDL_GetJoystickButton(void*, int button) { return (button & 1) == 0; }
API int16_t SDL_GetJoystickAxis(void*, int axis) { return axis & 1 ? -32768 : 32767; }
API uint8_t SDL_GetJoystickHat(void*, int) { return 0x0D; }
