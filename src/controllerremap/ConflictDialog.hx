package controllerremap;

import imgui.ImGui;
import imgui.Enums.ImGuiCol;
import imgui.Enums.ImGuiCond;
import imgui.Enums.ImGuiWindowFlags;
import imgui.Enums.ImGuiTableFlags;
import imgui.Enums.ImGuiTableColumnFlags;
import imgui.Structs.ImVec2;
import imgui.Structs.ImVec4;
import imgui.ref.BoolRef;
import controllerremap.ui.UiChrome;
import controllerremap.ui.UiScope;
import controllerremap.ui.ThemePalette;
import controllerremap.ui.EnhancedText;
import controllerremap.ui.WindowEffects;
import controllerremap.Remap.PendingEdit;

typedef ChangeRow={label:String,before:String,after:String};

/** A blocking, red warning with explicit before/after consequences. No game writes in draw. */
class ConflictDialog {
    static inline var TITLE="Binding conflict###ControllerRemap.Conflict";
    public static var choice=-1;
    public static var dismiss=false;
    public static var controllerNavigation=false;
    public static var focusRecovered(default,null)=false;
    static var seen:PendingEdit=null;
    static var visible=false;
    static var opening=false;
    static var opened:BoolRef;
    static var size:ImVec2;static var minimum:ImVec2;static var maximum:ImVec2;static var pivot:ImVec2;
    static var button:ImVec2;static var list:ImVec2;static var zero:ImVec2;static var available:ImVec2;
    static var pos:ImVec2;static var titlePos:ImVec2;static var band:ImVec2;static var end:ImVec2;
    static var redBackground:ImVec4;static var dim:ImVec4;
    static var rows:Array<ChangeRow>=[];
    static var heading="";
    static var familyHint="";
    static var tableFn:Void->Void;static var rowsFn:Void->Void;
    static var hintMeasure:ImVec2;static var legendMeasure:ImVec2;
    static var footerHint="";static var footerLegend="";static var footerFn:Void->Void;
    public static function init():Void {
        opened=new BoolRef(true);size=ImGui.vec2(760,620);minimum=ImGui.vec2(700,540);maximum=ImGui.vec2(1100,1000);pivot=ImGui.vec2(0.5,0.5);
        hintMeasure=ImGui.vec2(0,0);legendMeasure=ImGui.vec2(0,0);
        footerFn=drawFooter;footerLegend=ControllerLegend.text(EditorFocus.EDITOR,false,true,false);
        button=ImGui.vec2(144,30);list=ImGui.vec2(0,200);zero=ImGui.vec2(0,0);available=ImGui.vec2(0,0);
        pos=ImGui.vec2(0,0);titlePos=ImGui.vec2(0,0);band=ImGui.vec2(0,52);end=ImGui.vec2(0,0);
        var t=ThemePalette.current(),red=ThemePalette.status(ThemePalette.STATUS_DANGER);
        redBackground=ImGui.vec4(t.windowBg.x*0.8+red.x*0.2,t.windowBg.y*0.8+red.y*0.2,t.windowBg.z*0.8+red.z*0.2,1);
        dim=ImGui.vec4(0,0,0,0.68);tableFn=drawTable;rowsFn=drawRows;
    }
    public static function observe():Void {
        var edit=Remap.pendingEdit;
        if(edit==null)return;
        if(edit==seen)return;
        seen=edit;opening=true;opened.set(true);dismiss=false;
        heading=ActionLabels.display(edit.plan.action)+" - "+Remap.text(edit.plan.after);
        familyHint=InputFamilies.label(edit.plan.action)+" only. Other input families are kept.";
        footerHint=edit.plan.swap==null?edit.plan.swapReason:edit.swapText;
        rows=[];var layout=Remap.snapshot();
        var keys=[for(key in edit.plan.move.keys())key];keys.sort(Reflect.compare);
        for(key in keys)rows.push({label:ActionLabels.display(key),before:Remap.text(layout.get(key)),after:Remap.text(edit.plan.move.get(key))});
    }
    public static function reset():Void {seen=null;visible=false;opening=false;dismiss=false;choice=-1;rows=[];controllerNavigation=false;focusRecovered=false;}
    public static function active():Bool return visible||opening;
    public static function draw():Void {
        focusRecovered=false;
        if(seen==null)return;
        if(Remap.pendingEdit==null&&!visible&&!opening)return;
        // Another UI can clear native popup/focus state without resolving our pending edit.
        // Reopen that unresolved dialog instead of leaving an invisible modal lock behind.
        if(Remap.pendingEdit==seen&&!dismiss&&opened.get()&&choice<0&&!ImGui.isPopupOpen(TITLE)){
            opening=true;visible=false;
        }
        if(opening&&!dismiss&&Remap.pendingEdit!=null){ImGui.openPopup(TITLE);opening=false;}
        ImGui.setNextWindowSize(size,ImGuiCond.Appearing);ImGui.setNextWindowSizeConstraints(minimum,maximum);
        if(!visible){var vp=ImGui.getMainViewport();if(vp!=null)ImGui.setNextWindowPos(ImGui.ImGuiViewport_GetCenter(vp),ImGuiCond.Appearing,pivot);}
        ImGui.setNextWindowBgAlpha(1);
        ImGui.pushStyleColor(ImGuiCol.PopupBg,ThemePalette.current().windowBg);
        ImGui.pushStyleColor(ImGuiCol.Border,ThemePalette.status(ThemePalette.STATUS_DANGER));
        ImGui.pushStyleColor(ImGuiCol.TitleBgActive,redBackground);ImGui.pushStyleColor(ImGuiCol.ModalWindowDimBg,dim);
        var shown=ImGui.beginPopupModal(TITLE,opened,ImGuiWindowFlags.NoDocking|ImGuiWindowFlags.NoCollapse);
        var failure:Dynamic=null;
        if(shown){
            visible=true;
            try {
                if(dismiss||Remap.pendingEdit==null||!opened.get()){ImGui.closeCurrentPopup();visible=false;opening=false;}
                else if(ImGui.isKeyPressed(imgui.Enums.ImGuiKey.Escape,false))finish(0);
                else drawBody();
            }catch(e:Dynamic){failure=e;ImGui.closeCurrentPopup();choice=0;visible=false;}
            ImGui.endPopup();
        }else if(!opened.get()){choice=0;visible=false;}
        ImGui.popStyleColor(4);if(failure!=null)throw failure;
    }
    static function drawBody():Void {
        var edit=Remap.pendingEdit,red=ThemePalette.status(ThemePalette.STATUS_DANGER);
        ImGui.getCursorScreenPos(pos);ImGui.getContentRegionAvail(available);band.x=available.x;
        end.x=pos.x+band.x;end.y=pos.y+band.y;
        ImGui.ImDrawList_AddRectFilled(ImGui.getWindowDrawList(),pos,end,ImGui.colorConvertFloat4ToU32(redBackground),3);
        WindowEffects.gradientHeader(ImGui.getWindowDrawList(),pos.x,pos.y,band.x,3,ImGui.colorConvertFloat4ToU32(red),ImGui.colorConvertFloat4ToU32(red));
        var font=ImGui.getFont();if(font!=null)ImGui.pushFont(font,ImGui.getFontSize()*1.35);
        var titleFailure:Dynamic=null;
        try {
            var caption="BUTTON ALREADY ASSIGNED",measure=ImGui.calcTextSize(caption);
            titlePos.x=pos.x+Math.max(12,(band.x-measure.x)*0.5);titlePos.y=pos.y+(band.y-measure.y)*0.5;
            EnhancedText.shadowed(ImGui.getWindowDrawList(),titlePos,caption,ImGui.colorConvertFloat4ToU32(red));
        }catch(e:Dynamic)titleFailure=e;
        if(font!=null)ImGui.popFont();if(titleFailure!=null)throw titleFailure;
        ImGui.dummy(band);UiChrome.gap(12);
        note(heading);note(familyHint);
        UiChrome.gap(8);ImGui.getContentRegionAvail(available);
        ImGui.calcTextSize(footerHint,false,available.x,hintMeasure);ImGui.calcTextSize(footerLegend,false,available.x,legendMeasure);
        list.y=Math.max(24,available.y-hintMeasure.y-legendMeasure.y-132);UiScope.child("##conflictChanges",list,tableFn);
        footerFn();
    }
    static function drawFooter():Void {
        var edit=Remap.pendingEdit;
        UiChrome.gap(12);note(footerHint);UiChrome.gap(12);
        ImGui.getContentRegionAvail(available);ImGui.setCursorPosX(ImGui.getCursorPosX()+Math.max(0,(available.x-464)/2));
        if(controllerNavigation&&!ImGui.isAnyItemFocused()){
            ImGui.setWindowFocus();ImGui.setKeyboardFocusHere();focusRecovered=true;
        }
        if(UiChrome.ghostButton("Cancel##conflict",button))finish(0);
        ImGui.setItemDefaultFocus();ImGui.sameLine(0,16);
        ImGui.beginDisabled(edit.plan.swap==null);var failure:Dynamic=null;
        try {if(UiChrome.ghostButton("Swap##conflict",button))finish(2);}catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
        ImGui.sameLine(0,16);if(UiChrome.dangerButton("Confirm move##conflict",button))finish(1);
        UiChrome.gap(6);note(footerLegend);ControllerScroll.apply();
    }
    static function finish(result:Int):Void {choice=result;ImGui.closeCurrentPopup();visible=false;}
    static function drawTable():Void {UiScope.table("##changes",3,rowsFn,ImGuiTableFlags.SizingStretchProp|ImGuiTableFlags.BordersOuter|ImGuiTableFlags.BordersInnerH|ImGuiTableFlags.RowBg,zero,0);ControllerScroll.apply(true);}
    static function drawRows():Void {
        ImGui.tableSetupColumn("Action",ImGuiTableColumnFlags.WidthStretch,0.34);ImGui.tableSetupColumn("Current",ImGuiTableColumnFlags.WidthStretch,0.33);ImGui.tableSetupColumn("After move",ImGuiTableColumnFlags.WidthStretch,0.33);ImGui.tableHeadersRow();
        for(row in rows){ImGui.tableNextRow();ImGui.tableSetColumnIndex(0);note(row.label);ImGui.tableSetColumnIndex(1);note(row.before);ImGui.tableSetColumnIndex(2);note(row.after);}
    }
    static function note(text:String):Void {ImGui.pushTextWrapPos(0);var failure:Dynamic=null;try ImGui.textUnformatted(text)catch(e:Dynamic)failure=e;ImGui.popTextWrapPos();if(failure!=null)throw failure;}
}
