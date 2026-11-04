#define SFPAD_TEST
#include "../sfpad.cpp"
#include <cstdlib>
#include <fstream>
#include <string>
static int checks = 0;
static void check(bool value, const char* why) { ++checks; if (!value) { std::fprintf(stderr,"FAIL: %s\n",why); std::exit(1); } }
template<class T> T symbol(HMODULE m,const char* name) { auto p=GetProcAddress(m,name);check(p!=nullptr,name);return reinterpret_cast<T>(p); }
static void testXInput() {
    check(sfpad_pad_install()==-1,"missing both input backends is harmless");
    HMODULE engine=LoadLibraryW(L".\\directx.hdll");check(engine!=nullptr,"load fake DirectX input module");
    HMODULE xinput=GetModuleHandleW(L"XINPUT9_1_0.dll");check(xinput!=nullptr,"load fake XInput");
    auto state=symbol<XInputStateFn>(engine,"engine_xinput");
    auto set=symbol<void(*)(const XINPUT_STATE*,DWORD)>(xinput,"mock_xinput");
    check(sfpad_pad_install()==1,"XInput attaches without sdl.hdll");
    check(sfpad_pad_backend()==2,"correct backend reported");
    check(sfpad_pad_install()==1&&sfpad_pad_count(0)==1,"repeated XInput Start reports actual count");
    XINPUT_STATE input,output;
    for(int i=0;i<32;++i){
        std::memset(&input,i,sizeof(input));input.dwPacketNumber=1234+i;
        input.Gamepad.wButtons=WORD(i*123);input.Gamepad.bLeftTrigger=BYTE(i*8);input.Gamepad.bRightTrigger=BYTE(255-i*8);
        input.Gamepad.sThumbLX=-32768;input.Gamepad.sThumbRY=32767;
        set(&input,ERROR_SUCCESS);
        check(state(DWORD(i%5),&output)==ERROR_SUCCESS,"XInput success unchanged");
        check(std::memcmp(&input,&output,sizeof(input))==0,"entire XInput state and packet unchanged");
    }
    set(&input,ERROR_DEVICE_NOT_CONNECTED);std::memset(&output,0xA5,sizeof(output));XINPUT_STATE untouched=output;
    check(state(0,&output)==ERROR_DEVICE_NOT_CONNECTED,"XInput disconnect result unchanged");
    check(std::memcmp(&output,&untouched,sizeof(output))==0,"failed XInput call leaves output unchanged");
    check(state(0,nullptr)==ERROR_DEVICE_NOT_CONNECTED,"null state passed through safely");
    check(sfpad_pad_count(9)==34,"XInput counters exact");
    failWrites=true;check(sfpad_pad_uninstall()==-7&&sfpad_pad_status()==1,"XInput restore failure remains retryable");failWrites=false;
    check(sfpad_pad_uninstall()==1&&sfpad_pad_status()==0,"XInput original restored");
    auto before=sfpad_pad_count(9);state(0,&output);check(sfpad_pad_count(9)==before,"restored DirectX module bypasses helper");
    check(sfpad_pad_install()==1&&sfpad_pad_count(9)==0,"XInput restart resets session counters");
    check(sfpad_pad_uninstall()==1,"stop restarted XInput session");
    std::printf("PASS %d XInput checks: real DirectX import patch, untouched state/error results and restore\n",checks);
}
int main(int argc,char**) {
    if(argc>1){testXInput();return 0;}
    check(sfpad_pad_install()==-1,"missing engine is harmless");
    HMODULE engine=LoadLibraryW(L".\\sdl.hdll");check(engine!=nullptr,"load fake engine");
    HMODULE sdl=GetModuleHandleW(L"SDL3.dll");check(sdl!=nullptr,"load fake SDL3");
    auto poll=symbol<PollEventFn>(engine,"engine_poll");
    auto gpButton=symbol<GamepadButtonFn>(engine,"engine_gp_button");
    auto gpAxis=symbol<GamepadAxisFn>(engine,"engine_gp_axis");
    auto joyButton=symbol<JoyButtonFn>(engine,"engine_joy_button");
    auto joyAxis=symbol<JoyAxisFn>(engine,"engine_joy_axis");
    auto joyHat=symbol<JoyHatFn>(engine,"engine_joy_hat");
    auto setEvent=symbol<void(*)(const void*,bool)>(sdl,"mock_event");
    // Cannot record => cannot attach. Directory deliberately blocks the log filename.
    DeleteFileW(L"controller_helper_log.txt");CreateDirectoryW(L"controller_helper_log.txt",nullptr);
    check(sfpad_pad_install()==-4,"log-open failure reported");check(sfpad_pad_status()==0,"no hooks without log");
    RemoveDirectoryW(L"controller_helper_log.txt");
    check(sfpad_pad_install()==6,"six real PE imports patched");
    check(sfpad_pad_install()==6,"repeated Start returns actual count");
    check(sfpad_pad_count(0)==6,"active import snapshot");
    auto device=reinterpret_cast<void*>(1);
    for(int b=-1;b<=33;++b){
        check(gpButton(device,b)==((b&1)!=0),"gamepad bool unchanged");
        check(joyButton(device,b)==((b&1)==0),"joystick bool unchanged");
    }
    for(int a=-1;a<=17;++a){
        check(gpAxis(device,a)==(a&1?32767:-32768),"gamepad signed axis unchanged");
        check(joyAxis(device,a)==(a&1?-32768:32767),"joystick signed axis unchanged");
    }
    for(int h=-1;h<=5;++h)check(joyHat(device,h)==0x0D,"hat unchanged");
    check(sfpad_pad_count(2)==35&&sfpad_pad_count(4)==35,"poll counters exact");
    uint8_t input[128],output[128];std::memset(input,0xA5,sizeof(input));
    const uint32_t types[]={0x650,0x651,0x652,0x600,0x602,0x603,0x604,0x200};
    for(auto type:types){
        std::memcpy(input,&type,4);uint32_t id=9;std::memcpy(input+16,&id,4);
        input[20]=4;input[21]=1;int16_t value=32767;std::memcpy(input+24,&value,2);
        setEvent(input,true);check(poll(output),"event result unchanged");
        check(std::memcmp(input,output,128)==0,"every event byte unchanged");
    }
    setEvent(input,false);std::memset(output,0xB6,128);
    check(!poll(output)&&output[0]==0xB6,"false poll leaves event untouched");
    check(!poll(nullptr),"null poll unchanged");
    // Exhausting device history must not alias an existing slot or change input.
    for(int i=2;i<20;++i)check(gpButton(reinterpret_cast<void*>(uintptr_t(i)),1),"extra controller passes through");
    check(slotFor(gpSlot,reinterpret_cast<void*>(999))==-1,"full device table refuses aliasing");
    // Status is read-only and must not grow logs.
    auto before=logged;for(int i=0;i<100;++i)sfpad_pad_status();check(logged==before,"status has no log IO");
    failWrites=true;check(sfpad_pad_uninstall()==-7,"failed restore reported");
    check(sfpad_pad_status()==1&&sfpad_pad_count(0)==6,"failed restore remains retryable");
    failWrites=false;
    // A foreign patch must be preserved and reported, not overwritten.
    auto first=patches[0];DWORD old;VirtualProtect(first.slot,sizeof(void*),PAGE_READWRITE,&old);
    *first.slot=first.original;DWORD ignore;VirtualProtect(first.slot,sizeof(void*),old,&ignore);
    check(sfpad_pad_uninstall()==6,"restores remaining imports and accepts already restored slot");
    check(sfpad_pad_status()==0&&logFile==INVALID_HANDLE_VALUE,"Stop closes file");
    auto count=sfpad_pad_count(2);gpButton(device,1);check(sfpad_pad_count(2)==count,"engine no longer enters wrapper");
    check(sfpad_pad_uninstall()==0,"repeated Stop harmless");
    check(sfpad_pad_install()==6,"restart succeeds");check(sfpad_pad_count(2)==0,"new session counters reset");
    // A failed patch must roll back the attachment instead of reporting success.
    check(sfpad_pad_uninstall()==6,"stop before failed attach");
    failWrites=true;check(sfpad_pad_install()==-6,"failed attachment reported");
    check(sfpad_pad_status()==0,"failed attachment is not active");failWrites=false;
    check(sfpad_pad_install()==6,"restart after failure");
    AcquireSRWLockExclusive(&lockLog);
    for(int i=0;i<20000;++i)line("bounded event log with repeated device events %d",i);
    ReleaseSRWLockExclusive(&lockLog);
    check(logged<=LOG_CAP,"bounded file writes");check(sfpad_pad_uninstall()==6,"stop after cap");
    std::ifstream f("controller_helper_log.txt",std::ios::binary);std::string log((std::istreambuf_iterator<char>(f)),{});
    check(log.size()<=LOG_CAP,"log file is at most 1 MiB");
    check(log.find("uninstall: restored 6")!=std::string::npos,"final counters retained after cap");
    std::printf("PASS %d native checks: actual PE import patch/restore, pass-through, lifecycle and log cap\n",checks);
}
