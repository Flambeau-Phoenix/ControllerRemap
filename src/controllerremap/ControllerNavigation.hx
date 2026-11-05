package controllerremap;

import imgui.ImGui;
import imgui.Enums.ImGuiKey;

/** Native IO stays opaque: forward events directly and let SFCursor own navigation flags. */
class ControllerNavigation {
    @:hlNative("?sfcursor","keyboard_navigation_client")
    public static function configure(owner:hl.Bytes,enabled:Bool):Int return -9;
    public var status(default,null)=0;
    var available:Bool;
    var owner:hl.Bytes;
    var forwarded:Array<Bool>=[for(_ in 0...6)false];
    var keys:Array<Int>=[ImGuiKey.UpArrow,ImGuiKey.DownArrow,ImGuiKey.LeftArrow,ImGuiKey.RightArrow,ImGuiKey.Space,ImGuiKey.Escape];
    public function new(owner:hl.Bytes){this.owner=owner;available=hl.Api.isPrimLoaded(configure);}
    public function route(down:Array<Bool>,enabled:Bool,accept:Bool,submitEvents:Bool=true):Void {
        try status=available?configure(owner,enabled):-9 catch(_:Dynamic)status=-1;
        if(submitEvents)forward(down,enabled&&accept&&status==1);
    }
    function forward(down:Array<Bool>,enabled:Bool):Void {
        var io=ImGui.getIO();if(io==null)return;
        for(i in 0...keys.length){
            var value=enabled&&switch(i){
                case 0:down[12]||down[16];case 1:down[13]||down[17];
                case 2:down[14]||down[18];case 3:down[15]||down[19];
                case 4:down[0];case 5:down[1];default:false;
            };
            // Cursor/focus transitions can clear native input independently of this cache.
            // Refresh directions after a clear. Replaying A/B would activate a control twice.
            if((i<4&&value)||value!=forwarded[i]){ImGui.ImGuiIO_AddKeyEvent(io,keys[i],value);forwarded[i]=value;}
        }
    }
}
