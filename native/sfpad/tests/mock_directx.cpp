#define NOMINMAX
#include <windows.h>
#define XInputGetState sdk_XInputGetState
#include <xinput.h>
#undef XInputGetState
extern "C" __declspec(dllimport) DWORD WINAPI XInputGetState(DWORD,XINPUT_STATE*);
extern "C" __declspec(dllexport) DWORD WINAPI engine_xinput(DWORD player,XINPUT_STATE* state) {return XInputGetState(player,state);}
