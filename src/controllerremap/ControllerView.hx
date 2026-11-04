package controllerremap;

import imgui.ImGui;
import imgui.Structs.ImVec2;
import imgui.ImGui.ImDrawList;
import imgui.Enums.ImGuiStyleVar;
import controllerremap.ui.UiChrome;
import controllerremap.ui.ThemePalette;
import controllerremap.ui.DragDropHelper;

/** Retained vector controller. Buttons inspect cached assignments or supply a drag payload. */
class ControllerView {
    static var labels=["A","B","X","Y","LB","RB","LT","RT","<","=","L3","R3","Up","Dn","<",">"];
    static var xs=[372,416,328,372,108,372,108,372,218,266,108,280,164,164,120,208];
    static var ys=[202,158,158,114,64,64,20,20,128,128,128,218,176,264,220,220];
    static var origin:ImVec2;static var screen:ImVec2;static var available:ImVec2;
    static var target:ImVec2;static var size:ImVec2;static var extent:ImVec2;
    static var a:ImVec2;static var b:ImVec2;
    static var padding:ImVec2;
    static var x:Single;static var y:Single;static var scale:Single;
    public static function init():Void {
        origin=ImGui.vec2(0,0);screen=ImGui.vec2(0,0);available=ImGui.vec2(0,0);
        target=ImGui.vec2(0,0);size=ImGui.vec2(0,0);extent=ImGui.vec2(0,0);a=ImGui.vec2(0,0);b=ImGui.vec2(0,0);padding=ImGui.vec2(2,2);
    }
    public static function draw(selected:Int,highlighted:Array<Bool>,tooltips:Array<String>):Int {
        ImGui.getCursorPos(origin);ImGui.getCursorScreenPos(screen);ImGui.getContentRegionAvail(available);
        var width:Single=Math.min(560,Math.min(available.x,Math.max(200,available.y-48)*480/292));
        scale=width/480;x=screen.x+(available.x-width)*0.5;y=screen.y;
        var dl=ImGui.getWindowDrawList();var theme=ThemePalette.current();
        var fill=ImGui.colorConvertFloat4ToU32(theme.windowBg),border=ImGui.colorConvertFloat4ToU32(theme.border);
        box(dl,38,122,154,286,fill,border,42);
        box(dl,326,122,442,286,fill,border,42);
        box(dl,38,82,442,236,fill,border,46);
        var clicked=-1;size.x=40*scale;size.y=size.x;
        ImGui.pushStyleVar(ImGuiStyleVar.FramePadding,padding);var drawFailure:Dynamic=null;
        try for(i in 0...labels.length){
            target.x=origin.x+(available.x-width)*0.5+(xs[i]-20)*scale;
            target.y=origin.y+(ys[i]-20)*scale;ImGui.setCursorPos(target);
            ImGui.pushID_Int(i);var failure:Dynamic=null;
            try {
                if(UiChrome.navButton(labels[i],i==selected||highlighted[i],size))clicked=i;
                if(ImGui.isItemHovered())ImGui.setTooltip(tooltips[i]);
                DragDropHelper.buttonSource(i,Remap.PADS[i]);
            }catch(e:Dynamic)failure=e;
            ImGui.popID();if(failure!=null)throw failure;
        }catch(e:Dynamic)drawFailure=e;
        ImGui.popStyleVar();if(drawFailure!=null)throw drawFailure;
        // Restore normal layout after positioning the controller's individual controls.
        ImGui.setCursorPos(origin);extent.x=available.x;extent.y=292*scale;ImGui.dummy(extent);
        return clicked;
    }
    static function box(dl:ImDrawList,x1:Single,y1:Single,x2:Single,y2:Single,fill:Int,border:Int,rounding:Single):Void {
        a.x=x+x1*scale;a.y=y+y1*scale;b.x=x+x2*scale;b.y=y+y2*scale;
        ImGui.ImDrawList_AddRectFilled(dl,a,b,fill,rounding*scale);
        ImGui.ImDrawList_AddRect(dl,a,b,border,rounding*scale,1.5);
    }
}
