package controllerremap;

import imgui.ImGui;
import imgui.Structs.ImVec2;
import imgui.Structs.ImVec4;
import imgui.Enums.ImGuiCol;
import imgui.Enums.ImGuiStyleVar;
import simplelfg.ui.ThemePalette;

/** Local first-build chrome; shared SolarFlare/SimpleLFG helpers are unchanged. */
class ReleaseChrome {
    static var hover:ImVec4;static var selected:ImVec4;
    static var available:ImVec2;static var row:ImVec2;static var min:ImVec2;static var max:ImVec2;
    public static function init():Void {
        var t=ThemePalette.current();
        hover=ImGui.vec4(t.cellBg.x+0.06,t.cellBg.y+0.06,t.cellBg.z+0.06,1);
        selected=ImGui.vec4(t.cellBg.x*0.65+t.accent.x*0.35,t.cellBg.y*0.65+t.accent.y*0.35,t.cellBg.z*0.65+t.accent.z*0.35,1);
        available=ImGui.vec2(0,0);row=ImGui.vec2(0,30);min=ImGui.vec2(0,0);max=ImGui.vec2(0,0);
    }
    public static function styled(body:Void->Void):Void {
        var t=ThemePalette.current();
        ImGui.pushStyleVar(ImGuiStyleVar.FrameBorderSize,1.25);
        ImGui.pushStyleVar(ImGuiStyleVar.FrameRounding,4);
        ImGui.pushStyleColor(ImGuiCol.FrameBg,t.windowBg);
        ImGui.pushStyleColor(ImGuiCol.FrameBgHovered,hover);
        ImGui.pushStyleColor(ImGuiCol.FrameBgActive,selected);
        ImGui.pushStyleColor(ImGuiCol.Header,selected);
        ImGui.pushStyleColor(ImGuiCol.HeaderHovered,hover);
        ImGui.pushStyleColor(ImGuiCol.HeaderActive,selected);
        var failure:Dynamic=null;try body()catch(e:Dynamic)failure=e;
        ImGui.popStyleColor(6);ImGui.popStyleVar(2);if(failure!=null)throw failure;
    }
    public static function profileRow(caption:String,isSelected:Bool):Bool {
        ImGui.getContentRegionAvail(available);row.x=Math.max(1,available.x-2);
        var clicked=ImGui.selectable(caption,isSelected,0,row);
        ImGui.getItemRectMin(min);ImGui.getItemRectMax(max);
        var t=ThemePalette.current();
        ImGui.ImDrawList_AddRect(ImGui.getWindowDrawList(),min,max,
            ImGui.colorConvertFloat4ToU32(isSelected?t.accent:t.border),4,isSelected?1.6:1.0);
        return clicked;
    }
}
