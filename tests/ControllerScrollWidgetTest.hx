import imgui.ImGui;
import controllerremap.ModEntry;
import controllerremap.Remap;
import controllerremap.EditorFocus;
import controllerremap.ConflictDialog;
@:access(ControllerWidgetProbe)
@:access(controllerremap.ModEntry)
@:access(controllerremap.ControllerInput)
@:access(controllerremap.Remap)
@:access(controllerremap.BannerArt)
@:access(controllerremap.ConflictDialog)
@:access(controllerremap.BindingPlan)
@:access(controllerremap.ui.ToolWindow)
class ControllerScrollWidgetTest {
    static var checks=0;
    static var listScroll:Float=0;static var listLimit:Float=0;static var rightScroll:Float=0;static var bindingScroll:Float=0;
    static var footerEnd:Float=0;static var modalScroll:Float=0;static var changesScroll:Float=0;
    static var modalSize:imgui.Structs.ImVec2;
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function idle():Void ControllerWidgetProbe.idle();
    static function hold(index:Int,frames:Int):Void {ModEntry.controller.down[index]=true;for(_ in 0...frames)ControllerWidgetProbe.tick();ModEntry.controller.down[index]=false;idle();}
    static function list():Void {ModEntry.drawActionRows();listScroll=ImGui.getScrollY();listLimit=ImGui.getScrollMaxY();}
    static function right():Void {ModEntry.drawRight();rightScroll=ImGui.getScrollY();}
    static function binding():Void {ModEntry.drawBindingCardBody();bindingScroll=ImGui.getScrollY();}
    static function footer():Void {ConflictDialog.drawFooter();footerEnd=ImGui.getCursorPosY();ImGui.getWindowSize(modalSize);modalScroll=ImGui.getScrollMaxY();}
    static function changes():Void {ConflictDialog.drawTable();changesScroll=ImGui.getScrollY();}
    static function main():Void {
        var ctx=ImGui.createContext();if(ControllerWidgetProbe.prepare()!=1)throw "UI prepare failed";
        ModEntry.initUi();ModEntry.cursorLocked=true;ModEntry.controller.connected=true;ModEntry.controller.focused=true;
        if(Sys.args().indexOf("min")>=0)controllerremap.ui.ToolWindow.sizes.set(ModEntry.MAIN,ImGui.vec2(960,600));
        var raw=haxe.Resource.getBytes("controllerremap-banner");check(raw!=null,"banner is embedded in the compiled fixture");
        var png=new format.png.Reader(new haxe.io.BytesInput(raw)).read(),header=format.png.Tools.getHeader(png);
        check(header.width==ModEntry.banner.width&&header.height==ModEntry.banner.height,"embedded banner dimensions match the render aspect ratio");
        check(format.png.Tools.extract32(png).length==header.width*header.height*4,"embedded alpha PNG decodes completely");
        // CPU draw-list exercise only: texture upload is owned by the game renderer.
        ModEntry.banner.texture=(1:hl.I64);
        ModEntry.listFn=list;ModEntry.rightFn=right;ModEntry.bindingFn=binding;
        modalSize=ImGui.vec2(0,0);ConflictDialog.footerFn=footer;ConflictDialog.tableFn=changes;
        Remap.rows=[];
        for(i in 0...90){
            var id=i==0?"Jump":(i==1?"Attack":"ScrollAction"+i),pads=[{pad:"X",mod:-1,mode:-1}];
            Remap.rows.push({id:id,label:id,text:"X",pads:pads,planned:"",changed:false});Remap.baseline.set(id,pads);
        }
        ModEntry.viewDirty=true;idle();ControllerWidgetProbe.f10();
        check(ModEntry.banner.size.x==300&&ModEntry.banner.size.y>85&&ModEntry.banner.size.y<87,"banner fits the compact header at original aspect ratio");
        check(listLimit>0,"long action list exposes a real native scrollbar");
        var row=ModEntry.focusRowIndex;hold(21,20);
        check(listScroll>50&&rightScroll==0,"right stick scrolls focused action list without moving right pane");
        check(ModEntry.focusRowIndex==row&&ModEntry.editId==null,"scrolling does not move action focus or select an action");
        hold(20,30);check(listScroll==0,"right stick up returns list to top");
        ModEntry.focusSection(EditorFocus.PROFILES);idle();var before=rightScroll;
        hold(21,15);check(rightScroll>before&&listScroll==0,"profile focus scrolls its containing right pane alone");
        check(ModEntry.editorFocus.current==EditorFocus.PROFILES,"scrolling keeps profile focus");
        ModEntry.editId="Jump";ModEntry.syncEditor();ModEntry.bindingHeight=170;ModEntry.focusSection(EditorFocus.EDITOR);idle();
        before=rightScroll;hold(21,15);
        check(bindingScroll>0&&rightScroll==before,"scrollable binding child takes priority over its outer pane");
        ModEntry.controller.state.begin(0,ControllerWidgetProbe.now);idle();var capturedBefore=bindingScroll;
        hold(21,1);check(bindingScroll==capturedBefore,"Listen captures the right stick without scrolling");ModEntry.controller.cancel();idle();
        for(small in [false,true]){
            var plan=new controllerremap.BindingPlan("Jump",[{pad:"A",mod:-1,mode:-1}],Remap.snapshot());
            plan.swapReason="Choose a different button or confirm moving this binding. The current layout contains multiple conflicting actions, so a direct swap cannot preserve all alternatives.";
            Remap.pendingEdit={plan:plan,revision:Remap.revision,lines:[],swapText:""};
            ConflictDialog.reset();ConflictDialog.size.x=small?700:760;ConflictDialog.size.y=small?540:620;ConflictDialog.observe();
            // Overflow belongs to the changes list; footer controls stay fixed and visible.
            for(i in 0...30)ConflictDialog.rows.push({label:"Long conflicting action "+i,before:"LT + RT + X",after:"Unbound"});
            idle();check(modalSize.x==(small?700:760)&&modalSize.y==(small?540:620),"conflict popup opens at requested larger/default or minimum size");
            check(footerEnd<modalSize.y&&modalScroll==0,"conflict buttons and legend fit without a clipped bottom");
            hold(21,15);check(changesScroll>0,"right stick scrolls modal changes while its action button has focus");
            ControllerWidgetProbe.press(1);check(ConflictDialog.choice==0,"B still cancels the enlarged warning");
            Remap.cancelEdit();ConflictDialog.reset();idle();
        }
        ImGui.destroyContext(ctx);Sys.println("PASS native banner, focused scrolling and warning layout ("+checks+" checks)");
    }
}
