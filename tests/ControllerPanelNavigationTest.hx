import imgui.ImGui;
import controllerremap.ModEntry;
import controllerremap.Remap;
import controllerremap.EditorFocus;
@:access(ControllerWidgetProbe)
@:access(controllerremap.ModEntry)
@:access(controllerremap.ControllerInput)
@:access(controllerremap.Remap)
@:access(controllerremap.ui.ToolWindow)
class ControllerPanelNavigationTest {
    static var checks=0;
    static var legendPos:imgui.Structs.ImVec2;
    static var legendSize:imgui.Structs.ImVec2;
    static var legendBottom:Float=0;
    static var windowPos:imgui.Structs.ImVec2;
    static var windowSize:imgui.Structs.ImVec2;
    static function window():Void {ModEntry.drawWindow();ImGui.getWindowPos(windowPos);ImGui.getWindowSize(windowSize);}
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label+" (section="+ModEntry.editorFocus.current+", pending="+ModEntry.editorFocus.pending+")";}
    static function idle():Void ControllerWidgetProbe.idle();
    static function press(i:Int):Void ControllerWidgetProbe.press(i);
    static function legend():Void {
        ModEntry.drawLegend();ImGui.getWindowPos(legendPos);ImGui.getWindowSize(legendSize);legendBottom=ImGui.getCursorPosY();
    }
    static function section(s:Int,label:String):Void check(ModEntry.editorFocus.current==s&&ModEntry.editorFocus.pending<0&&ImGui.isAnyItemFocused(),label);
    static function main():Void {
        var ctx=ImGui.createContext();if(ControllerWidgetProbe.prepare()!=1)throw "UI prepare failed";
        ModEntry.initUi();ModEntry.cursorLocked=true;ModEntry.controller.connected=true;ModEntry.controller.focused=true;
        var small=Sys.args().indexOf("min")>=0;
        if(small)controllerremap.ui.ToolWindow.sizes.set(ModEntry.MAIN,ImGui.vec2(960,600));
        legendPos=ImGui.vec2(0,0);legendSize=ImGui.vec2(0,0);ModEntry.legendFn=legend;
        windowPos=ImGui.vec2(0,0);windowSize=ImGui.vec2(0,0);ModEntry.mainBodyFn=window;
        Remap.rows=[];
        for(id in ["Jump","Dash","Attack","Menu_LeftClick","Respawn","Map_ZoomIn","SpectateNext"]){
            var pads=[{pad:"X",mod:-1,mode:-1}];Remap.rows.push({id:id,label:id,text:"X",pads:pads,planned:"",changed:false});Remap.baseline.set(id,pads);
        }
        ModEntry.viewDirty=true;idle();ControllerWidgetProbe.f10();section(EditorFocus.ACTIONS,"open starts on list");
        press(2);section(EditorFocus.PROFILES,"forward cycle skips unselected editor");press(3);section(EditorFocus.ACTIONS,"reverse cycle skips unselected editor");
        press(12);section(EditorFocus.FILTERS,"Up from first row escapes to categories");
        check(ModEntry.categoryFocusIndex==0,"category entry focuses All actions");
        press(13);section(EditorFocus.FILTERS,"Down remains in category grid");check(ModEntry.categoryFocusIndex==3,"Down reaches next visible category row");
        ModEntry.controller.down[12]=true;for(_ in 0...70)ControllerWidgetProbe.tick();
        section(EditorFocus.FILTERS,"held Up from second category row stays in grid");check(ModEntry.categoryFocusIndex==0,"one Up reaches category above without repeating into Restore all");
        ModEntry.controller.down[12]=false;idle();
        press(17);press(16);section(EditorFocus.FILTERS,"left stick follows category grid");check(ModEntry.categoryFocusIndex==0,"left stick Up stays in categories from second row");
        press(15);check(ModEntry.categoryFocusIndex==1&&ModEntry.actionGroup==0,"Right browses category without changing filter");
        press(13);check(ModEntry.categoryFocusIndex==4,"Down preserves column between full rows");
        press(13);check(ModEntry.categoryFocusIndex==6,"Down reaches centered final category");
        press(12);check(ModEntry.categoryFocusIndex==4,"Up from centered final category reaches nearest button");
        press(14);check(ModEntry.categoryFocusIndex==3,"Left stays within category row");
        press(14);section(EditorFocus.FILTERS,"Left at category edge stays in grid");check(ModEntry.categoryFocusIndex==3,"Left edge cannot jump panes");
        press(12);press(15);press(15);press(15);check(ModEntry.categoryFocusIndex==2,"Right edge stays on final button in row");
        press(13);press(13);press(13);section(EditorFocus.OPTIONS,"only Down at bottom category row exits to options");
        press(1);section(EditorFocus.FILTERS,"B from options returns to selected category");
        press(5);check(ModEntry.actionGroup==1&&ModEntry.view.length==3,"RB changes category and visible action list");section(EditorFocus.FILTERS,"category focus follows selected category");
        press(0);section(EditorFocus.ACTIONS,"A enters filtered action list");check(ModEntry.editId==null,"category activation cannot also select an action");
        press(13);check(ModEntry.focusRowIndex==1,"Down navigates actual list rows");
        press(0);section(EditorFocus.EDITOR,"A enters binding controls");check(ModEntry.editId=="Dash"&&ModEntry.pendingListen<0,"selected action opens without triggering Listen");
        press(1);section(EditorFocus.ACTIONS,"B returns to previous list row");check(ModEntry.focusRowIndex==1,"list remembers focused row");
        press(14);section(EditorFocus.FILTERS,"Left escapes list to categories");
        press(13);press(13);press(13);section(EditorFocus.OPTIONS,"Down traverses category rows before reaching options");
        press(0);check(ModEntry.pendingEnable>=0,"A activates override checkbox");ModEntry.pendingEnable=-1;
        press(1);section(EditorFocus.FILTERS,"B escapes options");
        press(12);section(EditorFocus.WINDOW,"Up from categories reaches window actions");
        press(0);check(ModEntry.confirmClear,"A activates Restore all confirmation");press(0);check(ModEntry.pendingClear,"fresh A confirms Restore all");ModEntry.pendingClear=false;ModEntry.confirmClear=false;
        // A complete real-widget cycle crosses both panes and the scrolled controller card.
        var expected=[EditorFocus.FILTERS,EditorFocus.OPTIONS,EditorFocus.ACTIONS,EditorFocus.EDITOR,EditorFocus.PROFILES,EditorFocus.CONTROLLER,EditorFocus.WINDOW];
        for(s in expected){press(2);section(s,"X cycles to section "+s);check(legendSize.y==62&&legendBottom<=legendSize.y,"legend fits its reserved footer at section "+s);}
        for(s in [EditorFocus.CONTROLLER,EditorFocus.PROFILES,EditorFocus.EDITOR,EditorFocus.ACTIONS,EditorFocus.OPTIONS,EditorFocus.FILTERS,EditorFocus.WINDOW]){press(3);section(s,"Y reverses to section "+s);}
        press(2);press(2);press(2);section(EditorFocus.ACTIONS,"cycle returns to list");
        press(5);check(ModEntry.actionGroup==2&&ModEntry.view.length==1,"RB on list changes to Attacks");section(EditorFocus.ACTIONS,"list keeps focus on category switch");
        press(13);section(EditorFocus.FILTERS,"Down from last row loops to categories");
        press(5);press(5);check(ModEntry.actionGroup==4&&ModEntry.view.length==0,"empty Items category is reachable");section(EditorFocus.FILTERS,"empty category retains a selectable category");
        press(0);section(EditorFocus.FILTERS,"A on empty category cannot trap focus in empty list");
        press(2);section(EditorFocus.OPTIONS,"X leaves empty category for options");press(2);section(EditorFocus.EDITOR,"forward cycle skips empty list and reaches retained editor");
        press(3);section(EditorFocus.OPTIONS,"reverse cycle skips empty list");press(3);section(EditorFocus.FILTERS,"reverse cycle returns to category");
        press(3);section(EditorFocus.WINDOW,"Y escapes empty category");
        press(3);section(EditorFocus.CONTROLLER,"reverse cycle reaches right pane from window");
        check(legendPos.y>0&&legendSize.x>800&&legendBottom<=62,"persistent legend remains visible after right pane scrolling");
        check(legendPos.y+legendSize.y<=windowPos.y+windowSize.y,"legend footer stays inside main window bounds");
        ControllerWidgetProbe.f10();ControllerWidgetProbe.f10();check(ImGui.isAnyItemFocused(),"close/reopen retains selectable navigation");
        ImGui.destroyContext(ctx);Sys.println("PASS native panel navigation ("+checks+" checks; "+(small?"minimum":"default")+" window)");
    }
}
