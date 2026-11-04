#include <cstdint>
#define IMPORT extern "C" __declspec(dllimport)
#define API extern "C" __declspec(dllexport)
IMPORT bool SDL_PollEvent(void*);
IMPORT bool SDL_GetGamepadButton(void*, int);
IMPORT int16_t SDL_GetGamepadAxis(void*, int);
IMPORT bool SDL_GetJoystickButton(void*, int);
IMPORT int16_t SDL_GetJoystickAxis(void*, int);
IMPORT uint8_t SDL_GetJoystickHat(void*, int);
API bool engine_poll(void* p) { return SDL_PollEvent(p); }
API bool engine_gp_button(void* p, int b) { return SDL_GetGamepadButton(p,b); }
API int16_t engine_gp_axis(void* p, int a) { return SDL_GetGamepadAxis(p,a); }
API bool engine_joy_button(void* p, int b) { return SDL_GetJoystickButton(p,b); }
API int16_t engine_joy_axis(void* p, int a) { return SDL_GetJoystickAxis(p,a); }
API uint8_t engine_joy_hat(void* p, int h) { return SDL_GetJoystickHat(p,h); }
