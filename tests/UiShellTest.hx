import controllerremap.ui.ToolWindow;
import controllerremap.ui.ContextMenuSystem;
import controllerremap.ui.UiChrome;
import imgui.ImGui;
import imgui.ref.BoolRef;
class UiShellTest {
    static var checks=0;
    static var calls=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function body():Void calls++;
    static function fail():Void throw "callback failure";
    static function main():Void {
        ToolWindow.init();ToolWindow.register("test",1000,780,960,600);
        var open=new BoolRef(false);
        ToolWindow.drawMenuWindow("test",open,body);
        check(ImGui.begins==0&&ImGui.ends==0&&calls==0,"closed editor has no native window scope");
        check(ImGui.undocks==0,"closed panels do not alter docking state");
        open.set(true);ImGui.shown=false;
        ToolWindow.drawMenuWindow("test",open,body);
        check(ImGui.begins==1&&ImGui.ends==1&&calls==0,"clipped Begin(false) still gets End");
        check(ImGui.undocks==1,"open panels explicitly leave previously saved dock nodes");
        check(ImGui.styles==0&&UiChrome.depth==0,"clipped window restores styling");
        ImGui.shown=true;ToolWindow.drawMenuWindow("test",open,body);
        check(calls==1&&ImGui.begins==2&&ImGui.ends==2,"visible tool window renders once");
        var failed=false;try ToolWindow.drawMenuWindow("test",open,fail)catch(_:Dynamic)failed=true;
        check(failed&&ImGui.begins==3&&ImGui.ends==3,"throwing window body still closes native scope");
        check(ImGui.styles==0&&UiChrome.depth==0,"throwing window restores style stacks");
        ImGui.shown=false;ContextMenuSystem.draw("menu",body);
        check(ImGui.popupEnds==0&&calls==1,"closed popup does not End or draw");
        ImGui.shown=true;ContextMenuSystem.draw("menu",body);
        check(ImGui.popupEnds==1&&calls==2,"visible context menu pairs Begin/End");
        failed=false;try ContextMenuSystem.draw("menu",fail)catch(_:Dynamic)failed=true;
        check(failed&&ImGui.popupEnds==2,"throwing context menu closes before propagating");
        open.set(false);ToolWindow.requestFocus("test");ToolWindow.drawMenuWindow("test",open,body);
        check(ImGui.focuses==0,"closed panels do not steal focus");
        open.set(true);ToolWindow.drawMenuWindow("test",open,body);ToolWindow.drawMenuWindow("test",open,body);
        check(ImGui.focuses==1,"a requested panel focus is applied once");
        Sys.println("PASS "+checks+" exported UI scope checks");
    }
}
