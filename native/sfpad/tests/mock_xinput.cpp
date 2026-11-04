#define NOMINMAX
#include <windows.h>
#define XInputGetState sdk_XInputGetState
#include <xinput.h>
#undef XInputGetState
#include <cstring>
#define API extern "C" __declspec(dllexport)
static XINPUT_STATE saved = {};
static DWORD status = ERROR_SUCCESS;
API void mock_xinput(const XINPUT_STATE* state,DWORD result) { saved=*state;status=result; }
API DWORD WINAPI XInputGetState(DWORD,XINPUT_STATE* state) {
    if(status==ERROR_SUCCESS&&state)std::memcpy(state,&saved,sizeof(saved));
    return status;
}
