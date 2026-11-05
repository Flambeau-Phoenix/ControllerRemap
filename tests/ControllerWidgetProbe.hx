import imgui.ImGui;
import controllerremap.ModEntry;
import controllerremap.Remap;
import controllerremap.EditorFocus;
@:access(controllerremap.ModEntry)
@:access(controllerremap.ControllerInput)
@:access(controllerremap.ControllerNavigation)
@:access(controllerremap.Remap)
@:access(controllerremap.ui.ToolWindow)
class ControllerWidgetProbe {
    @:hlNative("sfuitest","prepare") static function prepare():Int return -1;
    @:hlNative("sfimgui","igNewFrame") static function newFrame():Void {}
    @:hlNative("sfimgui","igEndFrame") static function endFrame():Void {}
    static var checks=0;static var now=0.;
    static var foreign=false;static var focusForeign=false;static var foreignClicks=0;
    static function drawForeign():Void {
        if(!foreign)return;
        ImGui.begin("Other mod fixture",null,imgui.Enums.ImGuiWindowFlags.NoSavedSettings);
        if(focusForeign){ImGui.setWindowFocus();ImGui.setKeyboardFocusHere();focusForeign=false;}
        if(ImGui.button("Other mod button"))foreignClicks++;
        ImGui.end();
    }
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function tick():Void {
        now+=1./60;
        // Production callbacks run after the backend's NewFrame, not before it.
        newFrame();
        drawForeign();
        var c=ModEntry.controller;
        var wasOpen=ModEntry.open.get();
        c.state.update(c.down,true,true,wasOpen,now);
        ModEntry.observeWindowCommand(wasOpen,now);
        ModEntry.observeNavigation();
        ModEntry.observeSelection();
        ModEntry.refreshActionView();
        ModEntry.drawUiFrame(wasOpen);
        c.navigation.forward(c.down,ModEntry.open.get()&&c.state.navigation);
        endFrame();
    }
    static function idle():Void {for(_ in 0...4)tick();}
    static function press(index:Int):Void {ModEntry.controller.down[index]=true;tick();tick();ModEntry.controller.down[index]=false;idle();}
    static function f10():Void {for(_ in 0...20)tick();ModEntry.gameHotkey=true;tick();ModEntry.gameHotkey=false;idle();}
    static function popupOpen():Bool return ImGui.isPopupOpen("",imgui.Enums.ImGuiPopupFlags.AnyPopupId|imgui.Enums.ImGuiPopupFlags.AnyPopupLevel);
    static function alt():Void {
        ImGui.ImGuiIO_AddKeyEvent(ImGui.getIO(),imgui.Enums.ImGuiKey.LeftAlt,true);tick();
        ImGui.ImGuiIO_AddKeyEvent(ImGui.getIO(),imgui.Enums.ImGuiKey.LeftAlt,false);idle();
    }
    static function main():Void {
        Sys.println("Starting production widget fixture");var context=ImGui.createContext();var result=prepare();if(result!=1)throw "Native UI preparation failed: "+result;
        Sys.println("Context prepared");ModEntry.initUi();Sys.println("UI initialized");ModEntry.cursorLocked=true;
        ModEntry.controller.connected=true;ModEntry.controller.focused=true;
        Remap.rows=[];
        for(i in 0...3){
            var id="TestAction"+i,pads=[{pad:"X",mod:-1,mode:-1}];
            Remap.rows.push({id:id,label:"Action "+i,text:"X",pads:pads,planned:"",changed:false});
            Remap.baseline.set(id,pads);
        }
        ModEntry.view=[0,1,2];idle();
        var opening=ModEntry.controller.down;
        opening[5]=true;opening[6]=true;opening[7]=true;tick();
        check(!ModEntry.open.get(),"shortcut modifiers alone do not open the panel");
        opening[0]=true;idle();
        check(ModEntry.open.get(),"LT+RT+RB then A opens the production panel with cursor hidden");
        check(ModEntry.pointer.hidden,"controller opening requests hardware pointer suppression");
        check(ModEntry.editId==null&&ModEntry.pendingSelect<0&&ModEntry.pendingListen<0,"held opening combo does not activate a row or Listen");
        opening[6]=false;idle();
        check(ModEntry.editId==null&&ModEntry.pendingSelect<0,"partial shortcut release cannot activate a row with held A");
        for(i in 0...24)opening[i]=false;idle();
        check(ModEntry.editorFocus.current==EditorFocus.ACTIONS,"F10 focus starts on action list with cursor hidden");
        press(0);
        check(ModEntry.editId=="TestAction0","controller A selects the focused production table row");
        check(ModEntry.editorFocus.pending<0&&ModEntry.editorFocus.current==EditorFocus.EDITOR,"selection hands focus into the production editor child");
        check(ModEntry.pendingListen<0,"selecting a row must not activate Listen with the same A press");
        var height=ModEntry.bindingHeight;idle();check(height==ModEntry.bindingHeight,"editor height stays steady after selection");
        press(0);check(ModEntry.pendingListen==0,"a fresh A activates the production Listen button");
        ModEntry.pendingListen=-1;ModEntry.controller.state.begin(0,now);
        var c=ModEntry.controller;
        c.state.update(c.down,true,true,true,now+.1);c.down[1]=true;
        check(c.state.update(c.down,true,true,true,now+.2)==1,"Listen captures B as an assignable button");c.down[1]=false;c.cancel();
        ModEntry.focusSection(EditorFocus.ACTIONS);idle();press(15);
        check(ModEntry.editorFocus.current==EditorFocus.EDITOR&&ModEntry.editorFocus.pending<0,"right arrow enters the editor from the production action list");
        press(5);check(ModEntry.editorFocus.current==EditorFocus.PROFILES&&ModEntry.editorFocus.pending<0,"RB reaches the inline profile controls");
        press(5);check(ModEntry.editorFocus.current==EditorFocus.CONTROLLER&&ModEntry.editorFocus.pending<0&&!controllerremap.ControllerView.focusFirst,"RB reaches the initially offscreen controller diagram");
        press(4);check(ModEntry.editorFocus.current==EditorFocus.PROFILES&&ModEntry.editorFocus.pending<0,"LB returns to inline profiles");
        press(1);check(ModEntry.editorFocus.current==EditorFocus.ACTIONS&&ModEntry.editorFocus.pending<0,"B returns from the right pane to the action list");
        opening[5]=true;opening[6]=true;opening[7]=true;tick();opening[0]=true;idle();
        check(!ModEntry.open.get(),"same shortcut closes the production panel once");
        for(i in 0...24)opening[i]=false;idle();f10();
        check(ModEntry.open.get(),"F10 reopens after controller close");
        check(ImGui.isAnyItemFocused(),"reopening has a real focused widget");
        ImGui.setWindowFocus((null:String));idle();
        check(ImGui.isAnyItemFocused(),"hidden-cursor panel recovers a focused widget after external focus clear");
        ModEntry.focusSection(EditorFocus.ACTIONS);idle();press(0);press(12);press(0);
        check(popupOpen(),"controller opens the real button assignment dropdown");
        press(13);press(0);
        check(!popupOpen()&&ModEntry.padRef[0].get()==3&&ModEntry.pendingApply,"dropdown starts on current X and Down+A selects Y");
        if(!popupOpen()){press(0);}
        check(popupOpen(),"dropdown really is open before close/reopen regression");
        f10();check(!ModEntry.open.get()&&!popupOpen(),"closing dismisses the owned assignment dropdown");
        f10();check(!popupOpen()&&ImGui.isAnyItemFocused(),"reopening after dropdown close restores a selectable widget");
        opening[13]=true;tick();tick();
        check(ImGui.isKeyDown(imgui.Enums.ImGuiKey.DownArrow),"held controller direction reaches native IO");
        ImGui.ImGuiIO_ClearInputKeys(ImGui.getIO());tick();tick();
        check(ImGui.isKeyDown(imgui.Enums.ImGuiKey.DownArrow),"held direction recovers after an external native input clear");
        opening[13]=false;idle();
        ModEntry.cursorLocked=false;alt();check(!ModEntry.pointer.hidden&&ModEntry.open.get(),"Alt exposes mouse mode without closing the panel");
        foreign=true;focusForeign=true;idle();
        check(controllerremap.ui.ToolWindow.focused.get(ModEntry.MAIN)==false,"idle controller does not steal focus from mouse use in another mod");
        press(0);
        check(controllerremap.ui.ToolWindow.focused.get(ModEntry.MAIN)==true&&ImGui.isAnyItemFocused(),"fresh controller input reclaims a selectable control");
        check(ModEntry.pointer.hidden,"fresh controller input returns to hidden-pointer mode");
        check(foreignClicks==0&&ModEntry.pendingSelect<0&&ModEntry.editId==null,"reclaiming A does not activate either window");
        foreign=false;ModEntry.cursorLocked=true;idle();press(0);
        check(ModEntry.editId!=null,"a fresh A selects normally after focus recovery");
        var plan=new controllerremap.BindingPlan("TestAction0",[{pad:"X",mod:-1,mode:-1}],Remap.snapshot());
        Remap.pendingEdit={plan:plan,revision:Remap.revision,lines:[],swapText:""};
        controllerremap.ConflictDialog.observe();idle();
        check(popupOpen()&&ImGui.isAnyItemFocused(),"conflict modal has a focused action");
        ImGui.setWindowFocus((null:String));idle();
        check(popupOpen()&&ImGui.isAnyItemFocused(),"conflict modal recovers focus without falling back to the main page");
        press(0);
        check(controllerremap.ConflictDialog.choice==0&&!popupOpen(),"fresh A selects Cancel after conflict focus recovery");
        Remap.cancelEdit();controllerremap.ConflictDialog.reset();idle();
        Remap.pendingEdit={plan:plan,revision:Remap.revision,lines:[],swapText:""};
        controllerremap.ConflictDialog.observe();idle();press(1);
        check(controllerremap.ConflictDialog.choice==0&&!popupOpen(),"B cancels the conflict modal without applying the binding");
        Remap.cancelEdit();controllerremap.ConflictDialog.reset();idle();
        Remap.pendingEdit={plan:plan,revision:Remap.revision,lines:[],swapText:""};
        controllerremap.ConflictDialog.observe();idle();f10();
        check(!ModEntry.open.get()&&!popupOpen()&&Remap.pendingEdit==null,"F10 closes and clears an active conflict modal");
        f10();check(ModEntry.open.get()&&ImGui.isAnyItemFocused(),"reopening after a modal close restores normal controller focus");
        press(0);press(12);opening[0]=true;tick();tick();tick();
        check(popupOpen(),"holding A opens the assignment dropdown once");
        ImGui.ImGuiIO_ClearInputKeys(ImGui.getIO());tick();tick();tick();
        check(popupOpen(),"native input clear cannot replay held A and pick a dropdown choice");
        opening[0]=false;idle();
        for(_ in 0...20)tick();opening[5]=true;opening[6]=true;opening[7]=true;tick();opening[0]=true;idle();
        check(!ModEntry.open.get()&&!popupOpen(),"controller shortcut closes an active assignment dropdown cleanly");
        for(i in 0...24)opening[i]=false;idle();f10();
        Remap.profiles=["One","Two"];ModEntry.selectedProfile="One";ModEntry.profileCaption="One";
        ModEntry.focusSection(EditorFocus.PROFILES);idle();press(0);
        check(popupOpen(),"A opens the profile dropdown in the right pane");
        press(13);press(0);check(ModEntry.selectedProfile=="Two"&&!popupOpen(),"Down+A selects another profile");
        press(13);press(0);check(ModEntry.pendingLoad,"A activates the right pane Load button after dropdown selection");
        ImGui.destroyContext(context);Sys.println("PASS native production widgets ("+checks+" checks; hidden cursor, A selection, editor focus, Listen, B capture, stable height, right arrow)");
    }
}
