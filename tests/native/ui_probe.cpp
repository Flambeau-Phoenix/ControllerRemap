// Test-only setup for the real SFimgui DLL. Not part of any player payload.
#define HL_NAME(n) sfuitest_##n
#include <hl.h>
#undef _GUID
#define NOMINMAX
#include <windows.h>
#include <cstring>
#include <cstdio>
#include "imgui.h"

HL_PRIM int HL_NAME(prepare)() {
    auto module=GetModuleHandleW(L"sfimgui.hdll");if(!module)return -1;
    auto version=reinterpret_cast<const char*(*)()>(GetProcAddress(module,"igGetVersion"));
    auto check=reinterpret_cast<bool(*)(const char*,size_t,size_t,size_t,size_t,size_t,size_t)>(GetProcAddress(module,"igDebugCheckVersionAndDataLayout"));
    auto getIO=reinterpret_cast<ImGuiIO*(*)()>(GetProcAddress(module,"igGetIO_Nil"));
    if(!version||!check||!getIO)return -2;
    if(std::strcmp(version(),IMGUI_VERSION)){
        std::fprintf(stderr,"SFimgui version %s differs from probe header %s\n",version(),IMGUI_VERSION);return -3;
    }
    if(!check(IMGUI_VERSION,sizeof(ImGuiIO),sizeof(ImGuiStyle),sizeof(ImVec2),sizeof(ImVec4),sizeof(ImDrawVert),sizeof(ImDrawIdx))){std::fprintf(stderr,"Probe IO=%zu Style=%zu\n",sizeof(ImGuiIO),sizeof(ImGuiStyle));return -4;}
    auto io=getIO();if(!io)return -5;
    io->DisplaySize=ImVec2(1200,900);io->DeltaTime=1.0f/60;
    io->IniFilename=nullptr;io->LogFilename=nullptr;
    io->ConfigFlags|=ImGuiConfigFlags_NavEnableKeyboard|ImGuiConfigFlags_NoMouse|ImGuiConfigFlags_NoMouseCursorChange;
    // Keep normal runtime navigation visibility; forcing it concealed cursor-mode bugs.
    io->BackendFlags|=ImGuiBackendFlags_RendererHasTextures;
    return 1;
}
DEFINE_PRIM(_I32, prepare, _NO_ARG);
