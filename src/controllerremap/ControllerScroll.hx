package controllerremap;

import imgui.ImGui;
import imgui.Enums.ImGuiFocusedFlags;

/** Apply after child contents: the deepest focused scrollable window owns this frame's motion. */
class ControllerScroll {
    static var step:Single=0;
    static var consumed=false;
    public static function begin(pixels:Float):Void {step=pixels;consumed=false;}
    public static function apply(modalList:Bool=false):Void {
        var flags=(modalList?ImGuiFocusedFlags.RootAndChildWindows:ImGuiFocusedFlags.ChildWindows)|ImGuiFocusedFlags.NoPopupHierarchy;
        if(consumed||step==0||!ImGui.isWindowFocused(flags))return;
        var limit=ImGui.getScrollMaxY();if(limit<=0)return;
        ImGui.setScrollY(Math.max(0,Math.min(limit,ImGui.getScrollY()+step)));consumed=true;
    }
}
