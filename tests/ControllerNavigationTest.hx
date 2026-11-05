import controllerremap.ControllerNavigation;
import controllerremap.ControllerInput.CursorNative;
import imgui.ImGui;
import imgui.Enums.ImGuiKey;

/** Real SFimgui/SFCursor DLL smoke: no game, GPU frame, desktop input or pointer-to-integer casts. */
class ControllerNavigationTest {
    static function main():Void {
        if(!hl.Api.isPrimLoaded(ControllerNavigation.configure))throw "Updated SFCursor navigation primitive is missing";
        if(!hl.Api.isPrimLoaded(CursorNative.pointer))throw "Updated SFCursor pointer primitive is missing";
        var context=ImGui.createContext();
        if(context==null||ImGui.getIO()==null)throw "Cannot create native ImGui context";
        var owner=@:privateAccess "controllerremap-smoke".toUtf8();
        var nav=new ControllerNavigation(owner),down=[for(_ in 0...24)false];
        for(i in 0...1000){
            down[0]=i%2==0;nav.route(down,i%3!=0,true);
            if(nav.status<0)throw "Native navigation setup failed: "+nav.status;
        }
        nav.route(down,false,false);
        // This is the same opaque handle used by the production event-forwarding path.
        ImGui.ImGuiIO_AddKeyEvent(ImGui.getIO(),ImGuiKey.Enter,true);
        ImGui.ImGuiIO_AddKeyEvent(ImGui.getIO(),ImGuiKey.Enter,false);
        ImGui.destroyContext(context);
        Sys.println("PASS native controller navigation smoke (1000 route calls; opaque ImGuiIO handles)");
    }
}
