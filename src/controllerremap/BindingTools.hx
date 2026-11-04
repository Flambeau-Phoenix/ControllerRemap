package controllerremap;

import imgui.ImGui;
import imgui.Structs.ImVec2;
import imgui.Enums.ImGuiTableFlags;
import imgui.Enums.ImGuiTableColumnFlags;
import imgui.Enums.ImGuiSelectableFlags;
import controllerremap.ui.UiChrome;
import controllerremap.ui.UiScope;
import controllerremap.ui.DragDropHelper;

typedef UseRow={id:String,label:String,text:String,reason:String};

/** Button inspector and context menus. Draw reads cached data and queues commands. */
class BindingTools {
    public static var showLookup=false;
    public static var openProfilesRequested=false;
    public static var selectedAction="";
    public static var selectId="";
    public static var selectProfile="";
    public static var command="";
    public static var target="";
    public static var removeAlternative=-1;
    public static var alternativeAction="";
    public static var editorDraft=false;
    public static var saveRequested=false;
    public static var refreshRequested=false;
    public static var closeRequested=false;
    public static var canSave=false;
    static var actual=false;
    static var button=0;
    static var dirty=true;
    static var revision=-1;
    static var lookupRows:Array<UseRow>=[];
    static var summary="";
    static var buttons:Array<String>=[];
    static var firstButtons:Map<String,Int>=new Map();
    static var hasMode:Map<String,Bool>=new Map();
    static var contextAction="";
    static var contextProfile="";
    static var contextButton=0;
    static var contextIndex=-1;
    static var keySize:ImVec2;static var paletteSize:ImVec2;static var usesSize:ImVec2;static var panelAvail:ImVec2;
    static var paletteFn:Void->Void;static var usesFn:Void->Void;
    static var keyLabels:Array<String>=[];
    static var diagramHints:Array<String>=[];static var highlighted:Array<Bool>=[];static var observedAction="";
    static var size:ImVec2;static var listSize:ImVec2;static var rowSize:ImVec2;static var zero:ImVec2;
    static var barFn:Void->Void;static var fileFn:Void->Void;static var viewFn:Void->Void;
    static var actionFn:Void->Void;static var profileFn:Void->Void;static var alternativeFn:Void->Void;
    static var clearFn:Void->Void;static var resetFn:Void->Void;static var loadFn:Void->Void;static var saveFn:Void->Void;static var deleteFn:Void->Void;
    static var listFn:Void->Void;static var rowsFn:Void->Void;
    public static function init():Void {
        size=ImGui.vec2(144,30);keySize=ImGui.vec2(72,42);paletteSize=ImGui.vec2(0,0);usesSize=ImGui.vec2(0,0);panelAvail=ImGui.vec2(0,0);
        paletteFn=drawPalette;usesFn=drawUses;
        keyLabels=["A","B","X","Y","LB","RB","LT","RT","Back","Start","L3","R3","Up","Down","Left","Right","LS Up","LS Down","LS Left","LS Right","RS Up","RS Down","RS Left","RS Right"];listSize=ImGui.vec2(0,0);rowSize=ImGui.vec2(0,28);zero=ImGui.vec2(0,0);
        buttons=Remap.PADS.copy();
        diagramHints=[for(p in Remap.PADS)p];highlighted=[for(_ in Remap.PADS)false];
        barFn=drawBar;fileFn=drawFile;viewFn=drawView;actionFn=drawActionMenu;profileFn=drawProfileMenu;alternativeFn=drawAlternativeMenu;
        clearFn=confirmClear;resetFn=confirmReset;loadFn=confirmLoad;saveFn=confirmSave;deleteFn=confirmDelete;listFn=drawUseList;rowsFn=drawUseRows;
    }
    public static function clearTransient():Void {
        selectId="";selectProfile="";command="";target="";removeAlternative=-1;saveRequested=false;refreshRequested=false;closeRequested=false;
        contextAction="";contextProfile="";contextIndex=-1;alternativeAction="";openProfilesRequested=false;
    }
    public static function inspect(pad:String):Void {
        var index=Remap.PADS.indexOf(pad);if(index>=0)button=index;
        showLookup=true;dirty=true;
    }
    public static function observe():Void {
        if(revision!=Remap.revision){revision=Remap.revision;dirty=true;}
        if(observedAction!=selectedAction){observedAction=selectedAction;dirty=true;}
        if(!dirty)return;dirty=false;
        var layout=Remap.snapshot(actual);
        for(i in 0...16){
            highlighted[i]=false;var lines=[buttons[i],"Click to inspect; drag onto a binding to assign."];
            var uses=BindingPlan.uses(buttons[i],layout);
            if(uses.length==0)lines.push("No assignments.");
            for(use in uses){lines.push(ActionLabels.display(use.action)+": "+Remap.text(use.bindings));if(use.action==selectedAction)highlighted[i]=true;}
            diagramHints[i]=lines.join("\n");
        }
        firstButtons=new Map();hasMode=new Map();
        for(id in layout.keys()){
            var pads=layout.get(id);if(pads.length>0)firstButtons.set(id,Remap.padIndex(pads[0].pad));
            var yes=false;for(p in Remap.currentPads(id))if(p.mode>=0)yes=true;hasMode.set(id,yes);
        }
        lookupRows=[];
        for(use in BindingPlan.uses(Remap.PADS[button],layout)){
            var reasons:Array<String>=[];if(use.asButton)reasons.push("button");if(use.asHold)reasons.push("hold modifier");if(use.asMode)reasons.push("mode hold");
            lookupRows.push({id:use.action,label:ActionLabels.display(use.action),text:Remap.text(use.bindings),reason:reasons.join(", ")});
        }
        summary=Remap.PADS[button]+" - "+lookupRows.length+" action"+(lookupRows.length==1?"":"s");
    }
    public static function menuBar():Void UiMenus.bar(barFn);
    static function drawBar():Void {UiMenus.menu("File",fileFn);UiMenus.menu("View",viewFn);}
    static function drawFile():Void {
        if(UiMenus.item("Save profile",canSave&&Remap.pendingEdit==null))saveRequested=true;
        if(UiMenus.item("Refresh profiles",Remap.pendingEdit==null))refreshRequested=true;
        ImGui.separator();if(UiMenus.item("Close window"))closeRequested=true;
    }
    static function drawView():Void {
        if(UiMenus.item("Profiles panel"))openProfilesRequested=true;
        if(UiMenus.item("Button lookup panel"))showLookup=true;
    }
    public static function actionContext(id:String):Void {
        if(UiMenus.openForItem("##actionContext")){contextAction=id;if(Remap.pendingEdit==null)selectId=id;}
        UiMenus.popup("##actionContext",actionFn);
    }
    static function post(action:String,id:String):Void {command=action;target=id;}
    static function drawActionMenu():Void {
        if(contextAction==""){ImGui.closeCurrentPopup();return;}
        var editable=Remap.pendingEdit==null;
        if(UiMenus.item("Edit bindings",editable))selectId=contextAction;
        if(UiMenus.item("Show button uses",firstButtons.exists(contextAction))){button=firstButtons.get(contextAction);showLookup=true;dirty=true;}
        ImGui.separator();
        if(UiMenus.item("Remove mode holds",editable&&hasMode.get(contextAction)==true))post("direct",contextAction);
        UiMenus.menu("Unbind controller action...",clearFn,editable);
        UiMenus.menu("Restore original binding...",resetFn,editable);
    }
    static function confirmClear():Void {if(UiMenus.item("Confirm unbind"))post("clear",contextAction);}
    static function confirmReset():Void {if(UiMenus.item("Confirm restore action"))post("reset",contextAction);}
    public static function profileContext(name:String):Void {
        if(UiMenus.openForItem("##profileContext")){contextProfile=name;selectProfile=name;}
        UiMenus.popup("##profileContext",profileFn);
    }
    static function drawProfileMenu():Void {
        if(contextProfile==""){ImGui.closeCurrentPopup();return;}
        var enabled=Remap.pendingEdit==null;
        UiMenus.menu("Load profile...",loadFn,enabled);
        UiMenus.menu("Save current layout here...",saveFn,enabled&&!editorDraft);
        UiMenus.menu("Delete profile...",deleteFn,enabled);
    }
    static function confirmLoad():Void {if(UiMenus.item(Remap.dirty?"Confirm replace unsaved layout":"Load this profile"))post("loadProfile",contextProfile);}
    static function confirmSave():Void {if(UiMenus.item("Confirm overwrite profile"))post("saveProfile",contextProfile);}
    static function confirmDelete():Void {if(UiMenus.item("Confirm delete saved file"))post("deleteProfile",contextProfile);}
    public static function alternativeContext(index:Int,padIndex:Int):Void {
        if(UiMenus.openForItem("##alternativeContext")){contextIndex=index;contextButton=padIndex;alternativeAction=selectedAction;}
        UiMenus.popup("##alternativeContext",alternativeFn);
    }
    static function drawAlternativeMenu():Void {
        if(contextIndex<0){ImGui.closeCurrentPopup();return;}
        if(UiMenus.item("Show every use of this button")){button=contextButton;showLookup=true;dirty=true;}
        if(UiMenus.item("Remove this alternative",Remap.pendingEdit==null))removeAlternative=contextIndex;
    }
    public static function drawFloatingLookup():Void {
        ImGui.getContentRegionAvail(panelAvail);
        paletteSize.x=Math.floor(panelAvail.x*0.34);paletteSize.y=panelAvail.y;
        usesSize.x=panelAvail.x-paletteSize.x-12;usesSize.y=panelAvail.y;
        UiChrome.celChild("##controllerButtons",paletteSize,paletteFn);ImGui.sameLine(0,12);UiChrome.celChild("##controllerUses",usesSize,usesFn);
    }
    public static function drawControllerCard():Void {
        UiChrome.centeredHeader("Controller",30);UiChrome.gap(8);
        var picked=ControllerView.draw(button,highlighted,diagramHints);
        if(picked>=0)inspect(buttons[picked]);
        note("Click a button to inspect its assignments. Drag it onto a binding to assign it.");
    }
    static function drawPalette():Void {
        UiChrome.centeredHeader("Controller",38);UiChrome.gap(12);
        UiChrome.subHeader("Face buttons");drawKeys(0,4);UiChrome.gap(12);
        UiChrome.subHeader("Shoulders / triggers");drawKeys(4,8);UiChrome.gap(12);
        UiChrome.subHeader("D-pad");drawKeys(12,16);UiChrome.gap(12);
        if(UiChrome.groupHeader("Other buttons##lookupOther"))drawKeys(8,12);
        if(UiChrome.groupHeader("Stick directions##lookupSticks"))drawKeys(16,24);
        UiChrome.gap(12);note("Click to inspect. Drag a button onto a binding to assign it.");
    }
    static function drawKeys(first:Int,last:Int):Void {
        for(i in first...last){
            if((i-first)%2!=0)ImGui.sameLine(0,12);
            if(UiChrome.navButton(keyLabels[i],button==i,keySize)){button=i;dirty=true;}
            if(ImGui.isItemHovered())ImGui.setTooltip(buttons[i]);
            DragDropHelper.buttonSource(i,buttons[i]);
        }
    }
    static function drawUses():Void {
        UiChrome.centeredHeader("Assignments",38);UiChrome.gap(12);
        if(UiChrome.navButton("Layout##lookupSource",!actual,size)){actual=false;dirty=true;}
        ImGui.sameLine(0,8);if(UiChrome.navButton("Game now##lookupSource",actual,size)){actual=true;dirty=true;}
        UiChrome.gap(12);ImGui.textUnformatted(summary);
        note(actual?"All contexts, modifiers and mode holds.":(Remap.enabled?"Configured controller layout.":"Overrides off. Showing the configured layout."));UiChrome.gap(8);
        ImGui.getContentRegionAvail(listSize);listSize.y=Math.max(128,listSize.y);UiScope.child("##buttonUses",listSize,listFn);
    }
    static function drawUseList():Void {
        if(lookupRows.length==0){note("No actions use this button. Choose another button above.");return;}
        UiScope.table("##buttonUseTable",2,rowsFn,ImGuiTableFlags.SizingStretchProp|ImGuiTableFlags.BordersOuter|ImGuiTableFlags.BordersInnerH|ImGuiTableFlags.RowBg|ImGuiTableFlags.NoSavedSettings,zero,0);
    }
    static function drawUseRows():Void {
        ImGui.tableSetupColumn("Action",ImGuiTableColumnFlags.WidthStretch,0.46);ImGui.tableSetupColumn("Binding / use",ImGuiTableColumnFlags.WidthStretch,0.54);ImGui.tableHeadersRow();
        for(row in lookupRows){
            ImGui.tableNextRow();ImGui.tableSetColumnIndex(0);ImGui.pushID_Str(row.id);var failure:Dynamic=null;
            try {
                if(ImGui.selectable(row.label,selectedAction==row.id,ImGuiSelectableFlags.SpanAllColumns,rowSize)&&Remap.pendingEdit==null)selectId=row.id;
                if(ImGui.isItemHovered())ImGui.setTooltip(row.id);
                actionContext(row.id);
            }catch(e:Dynamic)failure=e;
            ImGui.popID();if(failure!=null)throw failure;
            ImGui.tableSetColumnIndex(1);note(row.text);ImGui.textDisabled(row.reason);
        }
    }
    static function note(text:String):Void {
        ImGui.pushTextWrapPos(0);var failure:Dynamic=null;try ImGui.textDisabled(text)catch(e:Dynamic)failure=e;
        ImGui.popTextWrapPos();if(failure!=null)throw failure;
    }
}
