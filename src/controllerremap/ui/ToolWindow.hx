package controllerremap.ui;

import imgui.ImGui;
import imgui.Enums.ImGuiCond;
import imgui.Enums.ImGuiStyleVar;
import imgui.Enums.ImGuiWindowFlags;
import imgui.Structs.ImVec2;
import imgui.ref.BoolRef;

/** Exported SolarFlare tool-window shell; layout stays ImGui-owned.
 * Host settings, docking and cursor dependencies are supplied by this mod instead.
 */
class ToolWindow {
    static var sizes:Map<String,ImVec2>=new Map();
    static var minima:Map<String,ImVec2>=new Map();
    static var positions:Map<String,ImVec2>=new Map();
    static var placed:Map<String,Bool>=new Map();
    static var focus:Map<String,Bool>=new Map();
    public static function requestFocus(title:String):Void focus.set(title,true);
    static var maximum:ImVec2;
    static var align:ImVec2;
    public static function init():Void {maximum=ImGui.vec2(2400,1600);align=ImGui.vec2(0.5,0.5);}
    public static function register(title:String,w:Single,h:Single,minW:Single,minH:Single):Void {
        sizes.set(title,ImGui.vec2(w,h));minima.set(title,ImGui.vec2(minW,minH));
        positions.set(title,ImGui.vec2(0,0));
    }
    public static function drawMenuWindow(title:String,open:BoolRef,body:Void->Void,flags:Int=0):Void {
        if(!open.get())return;
        if(focus.get(title)==true){ImGui.setNextWindowFocus();focus.remove(title);}
        ImGui.setNextWindowSize(sizes.get(title),ImGuiCond.FirstUseEver);
        ImGui.setNextWindowSizeConstraints(minima.get(title),maximum);
        if(!placed.exists(title)){
            var vp=ImGui.getMainViewport();
            if(vp!=null){var center=ImGui.ImGuiViewport_GetCenter(vp),position=positions.get(title),size=sizes.get(title);position.x=Math.max(0,center.x-size.x/2);position.y=Math.max(0,center.y-size.y/2);ImGui.setNextWindowPos(position,ImGuiCond.FirstUseEver);}
            placed.set(title,true);
        }
        ImGui.setNextWindowBgAlpha(1);
        var shade=UiChrome.pushCelShade();
        ImGui.pushStyleVar(ImGuiStyleVar.WindowTitleAlign,align);
        var begun=false;var failure:Dynamic=null;
        try {
            var shown=ImGui.begin(title,open,flags|ImGuiWindowFlags.MenuBar|ImGuiWindowFlags.NoDocking|ImGuiWindowFlags.NoCollapse);
            begun=true;if(shown)body();
        }catch(e:Dynamic)failure=e;
        if(begun)ImGui.end();
        ImGui.popStyleVar();UiChrome.popCelShade(shade);
        if(failure!=null)throw failure;
    }
}
