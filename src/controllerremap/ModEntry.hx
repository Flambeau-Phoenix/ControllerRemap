package controllerremap;

import imgui.ImGui;
import imgui.Structs.ImVec2;
import imgui.Enums.ImGuiKey;
import imgui.Enums.ImGuiCond;
import imgui.Enums.ImGuiWindowFlags;
import imgui.Enums.ImGuiTableFlags;
import imgui.Enums.ImGuiTableColumnFlags;
import imgui.Enums.ImGuiSelectableFlags;
import imgui.ref.BoolRef;
import imgui.ref.IntRef;
import controllerremap.ui.ThemePalette;
import controllerremap.ui.UiChrome;
import controllerremap.ui.UiScope;
import controllerremap.Remap.Pad;
import controllerremap.ui.ToolWindow;
import controllerremap.ui.EnhancedText;
import controllerremap.ui.DragDropHelper;
import controllerremap.ui.ImGuiLists;

/**
 * Controller Remap: one window (F10). Left: every action that has a pad binding. Right: edit the selected
 * action, save / load profiles, two switches. The draw path reads cached primitives only; every engine
 * read or write happens in observe() from a queued click.
 */
@:build(hlx.runtime.Mod.build())
class ModEntry {
    static inline var MAX_EDIT=4;
    static inline var MAIN="Controller Remap###ControllerRemap";
    static inline var PROFILES_WINDOW="Controller profiles###ControllerRemap.Profiles";
    static inline var LOOKUP_WINDOW="Button lookup###ControllerRemap.Lookup";
    static var profilesOpen:BoolRef;static var lookupOpen:BoolRef;
    static var mainBodyFn:Void->Void;static var profilesWindowFn:Void->Void;static var lookupWindowFn:Void->Void;
    static var profileIndexFn:Int->Void;static var swapIndexFn:Int->Void;
    static var open:BoolRef;
    static var enabledRef:BoolRef;
    static var swapRef:BoolRef;
    static var filter:Text;
    static var name:Text;
    static var padRef:Array<IntRef>;
    static var holdRef:Array<IntRef>;
    static var winSize:ImVec2;static var avail:ImVec2;static var leftSize:ImVec2;static var rightSize:ImVec2;
    static var listSize:ImVec2;static var btnSmall:ImVec2;static var btnMid:ImVec2;static var btnWide:ImVec2;static var zero:ImVec2;
    static var leftFn:Void->Void;static var rightFn:Void->Void;static var windowFn:Void->Void;static var listFn:Void->Void;
    static var styledFn:Void->Void;static var bindingFn:Void->Void;static var profileCardFn:Void->Void;static var controllerFn:Void->Void;
    static var bindingSize:ImVec2;static var profileSize:ImVec2;static var controllerSize:ImVec2;static var actionSize:ImVec2;
    static var cardAvail:ImVec2;static var clearSize:ImVec2;
    static var swapSearch:Text;static var swapQuery="";static var swapTarget="";static var pendingExchange="";
    static var swapRows:Array<Int>=[];static var swapDirty=true;static var swapRevision=-1;
    static var editCaption="";static var swapCaption="Choose another action";static var swapPreview="";
    static var profileSummary="";
    static var editModeHint="";static var editSkill=false;static var pendingRemoveMode=false;
    static var canSave=false;static var saveExists=false;static var nameDirty=true;static var filterActive=false;
    static var bindingHeight:Single=128;static var profileHeight:Single=136;
    static var pendingSelectId="";static var pendingResolve=-1;static var draftAlternative=-1;
    static var scrollToEditor=false;static var scrollToProfiles=false;
    static var actionsTab:ImVec2;static var lookupTab:ImVec2;

    // retained workflow state
    static var editId:String=null;static var editCount=0;
    static var view:Array<Int>=[];static var viewDirty=true;static var selectedRow=-1;
    static var profileLabels:Array<String>=[];static var selectedProfile="";static var labelsDirty=true;
    static var profilesInitialized=false;
    static var confirmClear=false;
    static var confirmReset=false;static var confirmSave=false;static var confirmLoad=false;
    static var deleteName="";static var pendingDelete="";
    static var actionGroup=0;static var groupButton:ImVec2;static var viewLabel="";
    static var revision=-1;static var countLabel="";
    static var minSize:ImVec2;static var maxSize:ImVec2;
    static var padFilter:Text;
    static var padQuery="";static var padSearch:Array<String>=[];
    static var originalPads:Array<Pad>=[];
    static var nextCursor:Float=0;
    static var cursorLocked:Null<Bool>=null;
    static var windowInput:WindowInput;
    static var gameF10=-1;static var nextKeyResolve:Float=0;
    static var gameHotkey=false;static var gameF10Down=false;
    // queued clicks, handled in observe()
    static var pendingSelect=-1;static var pendingApply=false;static var pendingReset=false;static var pendingSave=false;
    static var pendingLoad=false;static var pendingRefresh=false;static var pendingClear=false;
    static var pendingEnable:Int=-1;static var pendingSwap:Int=-1;
    static var failedAt:Float=-1;

    static function main():Void {
        ThemePalette.init();
        // Solid dark panel with a gold accent; opacity 1 so the window never shows the game through it.
        ThemePalette.applyHost(0x15131B,0x26222F,0xC9A24B,0xEFE9DA,1.0);
        UiChrome.init();ToolWindow.init();EnhancedText.init();DragDropHelper.init(Remap.PADS);ConflictDialog.init();ControllerView.init();
        ToolWindow.register(MAIN,1000,780,960,600);
        ToolWindow.register(PROFILES_WINDOW,620,560,520,420);
        ToolWindow.register(LOOKUP_WINDOW,840,680,760,520);
        profilesOpen=new BoolRef(false);lookupOpen=new BoolRef(false);
        mainBodyFn=drawWindow;profilesWindowFn=drawProfilesWindow;lookupWindowFn=drawLookupWindow;
        profileIndexFn=drawProfileIndex;swapIndexFn=drawSwapIndex;
        ReleaseChrome.init();
        BindingTools.init();
        open=new BoolRef(false);enabledRef=new BoolRef(true);swapRef=new BoolRef(false);
        windowInput=new WindowInput();
        filter=new Text(64);name=new Text(48);padFilter=new Text(32);swapSearch=new Text(64);
        padSearch=[for(p in Remap.PADS)p.toLowerCase()];
        padRef=[for(_ in 0...MAX_EDIT) new IntRef(0)];holdRef=[for(_ in 0...MAX_EDIT) new IntRef(0)];
        minSize=ImGui.vec2(940,560);maxSize=ImGui.vec2(10000,10000);
        groupButton=ImGui.vec2(144,30);
        actionsTab=ImGui.vec2(144,30);lookupTab=ImGui.vec2(144,30);
        winSize=ImGui.vec2(1000,760);avail=ImGui.vec2(0,0);leftSize=ImGui.vec2(0,0);rightSize=ImGui.vec2(0,0);
        bindingSize=ImGui.vec2(0,0);profileSize=ImGui.vec2(0,0);controllerSize=ImGui.vec2(0,0);actionSize=ImGui.vec2(0,28);cardAvail=ImGui.vec2(0,0);clearSize=ImGui.vec2(144,30);
        listSize=ImGui.vec2(0,0);btnSmall=ImGui.vec2(30,30);btnMid=ImGui.vec2(144,30);btnWide=ImGui.vec2(144,30);zero=ImGui.vec2(0,0);
        leftFn=drawLeft;rightFn=drawRight;windowFn=drawStyledWindow;styledFn=drawThemedWindow;listFn=drawActionRows;rowsFn=drawRows;profilesFn=drawProfiles;
        bindingFn=drawBindingCardBody;profileCardFn=drawProfileCardBody;controllerFn=BindingTools.drawControllerCard;
        ImGui.register(HlxRuntime.moduleName(),frame);
    }

    // ---------------- observe: engine reads/writes, file IO ----------------
    static function observeWindowInput(now:Float):Void {
        if(now>=nextCursor){
            nextCursor=now+0.05;
            try {
                var app:Dynamic=App.inst;
                var locked:Dynamic=app==null?null:HlxRuntime.resolveField(app,"lockMouse");
                // MenuApp has no camera lock; a missing App is still initializing.
                cursorLocked=app==null?null:(locked==true);
            }catch(_:Dynamic){cursorLocked=null;}
        }
        if(gameF10<0&&now>=nextKeyResolve){
            nextKeyResolve=now+1;
            try {var code:Dynamic=HlxRuntime.resolveStaticField(HlxRuntime.resolveType("hxd.Key"),"F10");if(Std.isOfType(code,Int))gameF10=code;}catch(_:Dynamic){}
        }
        gameHotkey=false;
        if(gameF10>=0){
            try {
                var down=hxd.Key.isDown(gameF10);
                gameHotkey=hxd.Key.isPressed(gameF10)||(down&&!gameF10Down);
                gameF10Down=down;
            }catch(_:Dynamic){gameF10Down=false;}
        }
    }
    static function observe(now:Float):Void {
        Remap.poll(now);
        if(!Remap.ready) return;
        if(!profilesInitialized){
            profilesInitialized=true;selectedProfile=Remap.activeProfile;name.set(Remap.activeProfile);nameDirty=true;labelsDirty=true;
        }
        if(ConflictDialog.choice>=0){pendingResolve=ConflictDialog.choice;ConflictDialog.choice=-1;}
        if(BindingTools.openProfilesRequested){profilesOpen.set(true);ToolWindow.requestFocus(PROFILES_WINDOW);BindingTools.openProfilesRequested=false;}
        if(BindingTools.showLookup){lookupOpen.set(true);ToolWindow.requestFocus(LOOKUP_WINDOW);BindingTools.showLookup=false;}
        if(BindingTools.closeRequested){open.set(false);BindingTools.closeRequested=false;}
        if(BindingTools.saveRequested){
            if(saveExists&&!confirmSave){confirmSave=true;confirmLoad=false;deleteName="";scrollToProfiles=true;profilesOpen.set(true);ToolWindow.requestFocus(PROFILES_WINDOW);}
            else {pendingSave=true;confirmSave=false;}
            BindingTools.saveRequested=false;
        }
        if(BindingTools.refreshRequested){pendingRefresh=true;BindingTools.refreshRequested=false;}
        if(BindingTools.selectId!=""){pendingSelectId=BindingTools.selectId;BindingTools.selectId="";}
        if(BindingTools.selectProfile!=""){selectedProfile=BindingTools.selectProfile;BindingTools.selectProfile="";confirmLoad=false;deleteName="";}
        var contextCommand=BindingTools.command,contextTarget=BindingTools.target;
        BindingTools.command="";BindingTools.target="";
        if(contextCommand=="clear"||contextCommand=="reset"||contextCommand=="direct")pendingSelectId=contextTarget;
        if(contextCommand=="loadProfile"){selectedProfile=contextTarget;pendingLoad=true;confirmLoad=false;}
        if(contextCommand=="saveProfile"){name.set(contextTarget);nameDirty=true;pendingSave=true;confirmSave=false;}
        if(contextCommand=="deleteProfile")pendingDelete=contextTarget;
        if(pendingResolve>=0){
            Remap.resolveEdit(pendingResolve);pendingResolve=-1;syncEditor();viewDirty=true;labelsDirty=true;
        }
        if(BindingTools.removeAlternative>=0){
            var index=BindingTools.removeAlternative;BindingTools.removeAlternative=-1;
            if(index<editCount&&BindingTools.alternativeAction==editId&&Remap.pendingEdit==null){removeEditorAlternative(index);pendingApply=true;}
        }
        // Commit the action being edited before switching selection or saving.
        if(pendingApply&&editId!=null){
            var pads:Array<Pad>=[];
            for(i in 0...editCount){
                var h=holdRef[i].get();
                if(h<0&&i<originalPads.length) pads.push({pad:Remap.PADS[padRef[i].get()],mod:originalPads[i].mod,mode:originalPads[i].mode});
                else pads.push(Remap.make(padRef[i].get(),h));
            }
            if(Remap.pendingEdit!=null&&Remap.pendingEdit.plan.action==editId)Remap.cancelEdit();
            Remap.requestEdit(editId,pads);viewDirty=true;labelsDirty=true;draftAlternative=-1;
            if(Remap.pendingEdit==null)syncEditor();else scrollToEditor=true;
        }
        if(pendingSelect>=0&&Remap.pendingEdit==null){
            var rows=Remap.rows;
            if(pendingSelect<view.length&&view[pendingSelect]<rows.length){
                selectedRow=pendingSelect;editId=rows[view[pendingSelect]].id;
                syncEditor();
            }
            pendingSelect=-1;
        }
        if(pendingSelectId!=""&&Remap.pendingEdit==null){
            for(row in Remap.rows)if(row.id==pendingSelectId){editId=row.id;syncEditor();ToolWindow.requestFocus(MAIN);viewDirty=true;break;}
        }
        pendingSelectId="";pendingSelect=-1;
        if((contextCommand=="clear"||contextCommand=="reset"||contextCommand=="direct")&&contextTarget!=editId)contextCommand="";
        if(contextCommand=="clear"&&Remap.pendingEdit==null){Remap.requestEdit(editId,[]);syncEditor();viewDirty=true;labelsDirty=true;}
        if(contextCommand=="reset")pendingReset=true;
        if(contextCommand=="direct")pendingRemoveMode=true;
        if(pendingReset&&editId!=null){
            Remap.requestEdit(editId,Remap.baselinePads(editId));viewDirty=true;
            if(Remap.pendingEdit==null)syncEditor();else scrollToEditor=true;
        }
        if(pendingRemoveMode&&editId!=null){
            var direct:Array<Pad>=[];
            for(p in Remap.currentPads(editId)){
                var next={pad:p.pad,mod:p.mod,mode:-1};var duplicate=false;
                for(existing in direct)if(existing.pad==next.pad&&existing.mod==next.mod)duplicate=true;
                if(!duplicate)direct.push(next);
            }
            Remap.requestEdit(editId,direct);if(Remap.pendingEdit==null)syncEditor();else scrollToEditor=true;
            viewDirty=true;labelsDirty=true;confirmSave=false;
        }
        pendingRemoveMode=false;
        if(pendingExchange!=""&&editId!=null){
            var target=pendingExchange;Remap.swapActions(editId,target);syncEditor();swapTarget=target;
            pendingExchange="";swapDirty=true;viewDirty=true;labelsDirty=true;confirmSave=false;
        }
        if(pendingSave){Remap.saveProfile(name.get());if(!Remap.dirty){selectedProfile=Remap.activeProfile;name.set(Remap.activeProfile);nameDirty=true;}}
        if(pendingLoad&&selectedProfile!=""){Remap.loadProfile(selectedProfile);if(!Remap.dirty){name.set(Remap.activeProfile);nameDirty=true;}syncEditor();viewDirty=true;}
        if(pendingRefresh){Remap.listProfiles();}
        if(pendingDelete!=""){
            var deleted=pendingDelete;
            if(Remap.deleteProfile(deleted)){
                if(selectedProfile==deleted)selectedProfile="";
                if(name.get().toLowerCase()==deleted.toLowerCase()){name.set("");nameDirty=true;}
            }
            pendingDelete="";labelsDirty=true;
        }
        if(pendingClear){Remap.clearAll();syncEditor();viewDirty=true;}
        if(pendingEnable>=0){Remap.clearBindNotice();Remap.setEnabled(pendingEnable==1);viewDirty=true;}
        if(pendingSwap>=0){Remap.clearBindNotice();Remap.setSwap(pendingSwap==1);viewDirty=true;}
        if(pendingApply||pendingReset||pendingSave||pendingLoad||pendingRefresh||pendingClear||pendingEnable>=0||pendingSwap>=0) labelsDirty=true;
        pendingApply=false;pendingReset=false;pendingSave=false;pendingLoad=false;pendingRefresh=false;pendingClear=false;pendingEnable=-1;pendingSwap=-1;
        if(revision!=Remap.revision){revision=Remap.revision;viewDirty=true;countLabel=Remap.overrideCount+" edited actions";if(editId!=null)editModeHint=Remap.modeHint(Remap.currentPads(editId));}
        if(selectedProfile!=""&&Remap.profiles.indexOf(selectedProfile)<0) selectedProfile="";
        enabledRef.set(Remap.enabled);swapRef.set(Remap.swapAB);
        if(labelsDirty||nameDirty){
            var clean=Remap.cleanName(name.get());canSave=Profile.validName(clean);saveExists=false;
            for(p in Remap.profiles)if(p.toLowerCase()==clean.toLowerCase())saveExists=true;
            nameDirty=false;
        }
        if(labelsDirty){
            labelsDirty=false;
            profileLabels=[for(p in Remap.profiles) (p.length>28?p.substr(0,25)+"...":p)+(p==Remap.activeProfile?(Remap.dirty?"  (modified)":"  (loaded)"):"")+"###profile_row"];
            profileSummary=Remap.activeProfile==""?(Remap.dirty?"Unsaved layout":"No profile loaded"):(Remap.dirty?"Modified: ":"Loaded: ")+Remap.activeProfile;
        }
        if(viewDirty){
            viewDirty=false;
            var q=filter.get().toLowerCase();
            filterActive=q!="";
            view=[];
            for(i in 0...Remap.rows.length){
                var r=Remap.rows[i];
                if(ActionGroups.matches(actionGroup,r.id,r.text,r.planned,q,r.label)) view.push(i);
            }
            viewLabel=view.length+" of "+Remap.rows.length+" actions";
            selectedRow=-1;
            if(editId!=null) for(i in 0...view.length) if(Remap.rows[view[i]].id==editId) selectedRow=i;
        }
        if(swapRevision!=Remap.revision){swapRevision=Remap.revision;swapDirty=true;}
        if(swapDirty){
            swapDirty=false;swapRows=[];
            for(i in 0...Remap.rows.length){var row=Remap.rows[i];if(row.id!=editId&&(swapQuery==""||row.id.toLowerCase().indexOf(swapQuery)>=0||row.label.toLowerCase().indexOf(swapQuery)>=0))swapRows.push(i);}
            swapCaption=swapTarget==""?"Choose another action":ActionLabels.display(swapTarget);
            swapPreview=swapTarget==""?"Select an action to exchange all of its controller bindings.":Remap.text(Remap.layoutPads(editId))+"  <->  "+Remap.text(Remap.layoutPads(swapTarget));
        }
        BindingTools.selectedAction=editId==null?"":editId;
        BindingTools.canSave=canSave&&draftAlternative<0;
        BindingTools.editorDraft=draftAlternative>=0;
        BindingTools.observe();ConflictDialog.observe();
    }

    static function syncEditor():Void {
        if(editId==null) return;
        editCaption=ActionLabels.display(editId);swapTarget="";swapQuery="";swapSearch.set("");swapDirty=true;
        editSkill=["WeaponSkill1","WeaponSkill2","WeaponSkill3","WeaponSkill4","Skill1","Skill2","Skill3","Skill4"].indexOf(editId)>=0;
        originalPads=Remap.currentPads(editId);editCount=Std.int(Math.min(originalPads.length,MAX_EDIT));
        editModeHint=Remap.modeHint(originalPads);
        for(i in 0...MAX_EDIT){
            padRef[i].set(i<editCount?Remap.padIndex(originalPads[i].pad):0);
            var h=i<editCount?Remap.holdIndex(originalPads[i]):0;
            if(i<editCount){var candidate=Remap.make(padRef[i].get(),h);if(candidate.mod!=originalPads[i].mod||candidate.mode!=originalPads[i].mode)h=-1;}
            holdRef[i].set(h);
        }
        confirmReset=false;
        draftAlternative=-1;
        bindingHeight=270+editCount*30;
    }
    static function removeEditorAlternative(index:Int):Void {
        for(k in index...editCount-1){padRef[k].set(padRef[k+1].get());holdRef[k].set(holdRef[k+1].get());if(k+1<originalPads.length)originalPads[k]=originalPads[k+1];}
        editCount--;draftAlternative=-1;confirmSave=false;
    }
    static function clearTransientState():Void {
        pendingSelect=-1;editId=null;editCount=0;selectedRow=-1;originalPads=[];
        confirmClear=false;confirmReset=false;confirmSave=false;confirmLoad=false;deleteName="";
        padFilter.set("");padQuery="";
        swapTarget="";swapQuery="";swapSearch.set("");swapDirty=true;pendingExchange="";
        bindingHeight=128;profileHeight=136;
        editModeHint="";editSkill=false;pendingRemoveMode=false;
        pendingSelectId="";pendingResolve=-1;draftAlternative=-1;scrollToEditor=false;scrollToProfiles=false;
        Remap.cancelEdit();Remap.clearBindNotice();BindingTools.clearTransient();profilesOpen.set(false);lookupOpen.set(false);ConflictDialog.reset();
    }

    // ---------------- draw: frozen primitives and retained controls ----------------
    static function note(text:String):Void {
        ImGui.pushTextWrapPos(0);var failure:Dynamic=null;
        try ImGui.textDisabled(text)catch(e:Dynamic)failure=e;
        ImGui.popTextWrapPos();if(failure!=null)throw failure;
    }
    static function ghost(label:String,size:ImVec2,disabled:Bool=false):Bool {
        ImGui.beginDisabled(disabled);var result=false;var failure:Dynamic=null;
        try result=UiChrome.ghostButton(label,size)catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;return result;
    }
    static function combo(id:String,ref:IntRef,options:Array<String>):Void {
        var current=ref.get();if(current>=options.length){current=0;ref.set(0);}
        if(!ImGui.beginCombo(id,current<0?"Existing combined hold":options[current]))return;
        var failure:Dynamic=null;
        try {
            if(options==Remap.PADS){
                ImGui.setNextItemWidth(180);
                if(ImGui.inputTextWithHint("##buttonFilter","Find button",padFilter.bytes,padFilter.size))padQuery=padFilter.get().toLowerCase();
            }
            var query=options==Remap.PADS?padQuery:"";var matches=0;
            for(k in 0...options.length){
                if(query!=""&&padSearch[k].indexOf(query)<0)continue;
                matches++;ImGui.pushID_Int(k);var error:Dynamic=null;var picked=false;
                try picked=ImGui.selectable(options[k],k==current)catch(e:Dynamic)error=e;
                ImGui.popID();if(error!=null)throw error;
                if(picked){ref.set(k);pendingApply=true;confirmSave=false;}
            }
            if(matches==0)ImGui.textDisabled("No matching buttons.");
        }catch(e:Dynamic)failure=e;
        ImGui.endCombo();if(failure!=null)throw failure;
    }
    static function drawLeft():Void {
        UiChrome.centeredHeader("Choose an action",38);UiChrome.gap(12);
        ImGui.getContentRegionAvail(cardAvail);var startX=ImGui.getCursorPosX();
        var columns=Std.int(Math.max(2,Math.min(4,Math.floor((cardAvail.x+16)/(groupButton.x+16)))));
        for(i in 0...ActionGroups.labels.length){
            var column=i%columns;
            var inRow=Std.int(Math.min(columns,ActionGroups.labels.length-i+column));
            var spacing=(cardAvail.x-inRow*groupButton.x)/(inRow+1);
            if(column!=0)ImGui.sameLine(0,0);
            else if(i>0)UiChrome.gap(4);
            ImGui.setCursorPosX(startX+spacing+column*(groupButton.x+spacing));
            if(UiChrome.navButton(ActionGroups.labels[i],actionGroup==i,groupButton)){actionGroup=i;viewDirty=true;}
            if(ImGui.isItemHovered())ImGui.setTooltip(ActionGroups.descriptions[i]);
        }
        UiChrome.gap(8);
        ImGui.beginDisabled(Remap.pendingEdit!=null);var toggleFailure:Dynamic=null;
        try drawToolbar()catch(e:Dynamic)toggleFailure=e;
        ImGui.endDisabled();if(toggleFailure!=null)throw toggleFailure;
        UiChrome.gap(8);
        ImGui.getContentRegionAvail(cardAvail);ImGui.setNextItemWidth(Math.max(100,cardAvail.x-152));
        if(ImGui.inputTextWithHint("##filter","Search actions or bindings",filter.bytes,filter.size))viewDirty=true;
        ImGui.sameLine(0,8);
        if(ghost("Clear##filter",clearSize,!filterActive&&actionGroup==0)){filter.set("");actionGroup=0;viewDirty=true;}
        if(ImGui.isItemHovered())ImGui.setTooltip("Clear the search and show all actions.");
        ImGui.textDisabled(viewLabel);ImGui.sameLine(0,12);ImGui.textDisabled(countLabel);
        ImGui.getContentRegionAvail(listSize);UiScope.child("##actionList",listSize,listFn);
    }
    static function drawActionRows():Void {
        if(view.length==0){note("No actions match. Clear the search or choose another group.");return;}
        UiScope.table("##actions",2,rowsFn,ImGuiTableFlags.SizingStretchProp|ImGuiTableFlags.BordersOuter|ImGuiTableFlags.BordersInnerH|ImGuiTableFlags.RowBg|ImGuiTableFlags.NoSavedSettings,zero,0);
    }
    static var rowsFn:Void->Void=null;
    static function drawRows():Void {
        ImGui.tableSetupColumn("Action",ImGuiTableColumnFlags.WidthStretch,0.48);
        ImGui.tableSetupColumn("Controller binding",ImGuiTableColumnFlags.WidthStretch,0.52);
        ImGui.tableHeadersRow();
        for(i in 0...view.length){
            var row=Remap.rows[view[i]];
            ImGui.tableNextRow();ImGui.tableSetColumnIndex(0);ImGui.pushID_Str(row.id);
            var failure:Dynamic=null;
            try {
                if(ImGui.selectable(row.label,i==selectedRow,ImGuiSelectableFlags.SpanAllColumns,actionSize)&&Remap.pendingEdit==null)pendingSelect=i;
                if(ImGui.isItemHovered())ImGui.setTooltip(row.id);
                BindingTools.actionContext(row.id);
            }catch(e:Dynamic)failure=e;
            ImGui.popID();if(failure!=null)throw failure;
            ImGui.tableSetColumnIndex(1);note(row.text);
            if(row.changed){
                ImGui.pushTextWrapPos(0);var error:Dynamic=null;
                try ImGui.textColored(ThemePalette.status(ThemePalette.STATUS_INFO),row.planned)catch(e:Dynamic)error=e;
                ImGui.popTextWrapPos();if(error!=null)throw error;
            }
        }
    }
    static function drawRight():Void {
        if(scrollToEditor){ImGui.setScrollY(0);scrollToEditor=false;}
        if(scrollToProfiles){ImGui.setScrollY(bindingHeight+12);scrollToProfiles=false;}
        bindingSize.x=0;bindingSize.y=bindingHeight;
        UiChrome.celChild("##bindingCard",bindingSize,bindingFn);UiChrome.gap(8);
        profileSize.x=0;profileSize.y=profileHeight;
        UiChrome.celChild("##profileCard",profileSize,profileCardFn);UiChrome.gap(8);
        ImGui.getContentRegionAvail(cardAvail);controllerSize.x=0;
        controllerSize.y=Math.max(350,cardAvail.y-4);
        UiChrome.celChild("##controllerCard",controllerSize,controllerFn);
    }
    static function drawBindingCardBody():Void {
        var top=ImGui.getCursorPosY();drawBinding();bindingHeight=Math.max(128,ImGui.getCursorPosY()-top+20);
    }
    static function drawProfileCardBody():Void {
        var top=ImGui.getCursorPosY();
        UiChrome.centeredHeader("Layout profile",38);UiChrome.gap(8);
        ImGui.getContentRegionAvail(cardAvail);var startX=ImGui.getCursorPosX();
        ImGui.alignTextToFramePadding();ImGui.pushTextWrapPos(startX+Math.max(80,cardAvail.x-160));
        var failure:Dynamic=null;try ImGui.textDisabled(profileSummary)catch(e:Dynamic)failure=e;
        ImGui.popTextWrapPos();if(failure!=null)throw failure;
        ImGui.sameLine(startX+cardAvail.x-btnMid.x,0);
        if(ghost("Profiles...##manage",btnMid)){profilesOpen.set(true);ToolWindow.requestFocus(PROFILES_WINDOW);}
        if(ImGui.isItemHovered())ImGui.setTooltip("Bindings apply immediately. Save a profile to keep your layout after restarting.");
        profileHeight=Math.max(116,ImGui.getCursorPosY()-top+24);
    }
    static function drawBinding():Void {
        UiChrome.centeredHeader("Edit bindings",38);UiChrome.gap(12);
        if(editId==null){note("Select an action on the left. You can change its buttons or swap its complete bindings with another action.");return;}
        UiChrome.subHeader(editCaption);if(ImGui.isItemHovered())ImGui.setTooltip(editId);
        note("Choose a button and its hold.");
        drawBindingFields();
        if(Remap.pendingEdit!=null){coloredNote("Resolve the binding conflict in the warning dialog.",ThemePalette.STATUS_DANGER);return;}
        UiChrome.gap(8);UiChrome.subHeader("Swap with another action");
        ImGui.getContentRegionAvail(cardAvail);ImGui.setNextItemWidth(Math.max(100,cardAvail.x-152));
        drawSwapTarget();ImGui.sameLine(0,8);
        if(ghost("Swap bindings##exchange",btnWide,swapTarget==""))pendingExchange=swapTarget;
        if(ImGui.isItemHovered())ImGui.setTooltip("Exchange all button alternatives and hold combinations between these actions. Swap again to reverse it.");
        note(swapPreview);
    }
    static function coloredNote(text:String,status:Int):Void {
        ImGui.pushTextWrapPos(0);var failure:Dynamic=null;
        try ImGui.textColored(ThemePalette.status(status),text)catch(e:Dynamic)failure=e;
        ImGui.popTextWrapPos();if(failure!=null)throw failure;
    }
    static function drawBindingFields():Void {
        var removeAt=-1;
        for(i in 0...editCount){
            ImGui.pushID_Int(i);var failure:Dynamic=null;
            try {
                ImGui.setNextItemWidth(112);combo("##pad",padRef[i],Remap.PADS);
                var dropped=DragDropHelper.buttonTarget();
                if(dropped!=null){padRef[i].set(Remap.padIndex(dropped));pendingApply=true;}
                BindingTools.alternativeContext(i,padRef[i].get());
                ImGui.sameLine(0,6);ImGui.setNextItemWidth(156);combo("##hold",holdRef[i],Remap.HOLD_LABELS);
                ImGui.sameLine(0,6);if(ghost("x##remove",btnSmall,Remap.pendingEdit!=null))removeAt=i;
                if(ImGui.isItemHovered())ImGui.setTooltip("Remove this button alternative.");
            }catch(e:Dynamic)failure=e;
            ImGui.popID();if(failure!=null)throw failure;
        }
        if(removeAt>=0){
            removeEditorAlternative(removeAt);pendingApply=true;
        }
        if(Remap.bindAction==editId&&Remap.bindMessage!=""){
            coloredNote(Remap.bindMessage,Remap.bindState==1?ThemePalette.STATUS_SUCCESS:(Remap.bindState<0||Remap.bindState==3?ThemePalette.STATUS_DANGER:ThemePalette.STATUS_INFO));
        }
        ImGui.beginDisabled(Remap.pendingEdit!=null);var failure:Dynamic=null;
        try drawBindingActions()catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
    }
    static function drawBindingActions():Void {
        if(editCount==0)note("This action has no controller binding.");
        if(ghost("+ Add button",btnMid,editCount>=MAX_EDIT||draftAlternative>=0)){padRef[editCount].set(0);holdRef[editCount].set(0);draftAlternative=editCount;editCount++;confirmSave=false;Remap.clearBindNotice();}
        ImGui.sameLine(0,6);
        if(ghost(confirmReset?"Confirm reset?###reset":"Reset action###reset",btnWide)){
            if(confirmReset){pendingReset=true;confirmReset=false;}else confirmReset=true;
        }
        if(Remap.applyFailed){UiChrome.gap(8);if(ghost("Retry apply",btnMid))pendingApply=true;}
        if(confirmReset)note("Click again to restore this action's original controller binding.");
        if(draftAlternative>=0)note("Choose a button or hold for the new alternative to bind it.");
        if(editModeHint!=""){
            note(editModeHint);
            if(ghost("Remove mode hold##direct",btnWide))pendingRemoveMode=true;
            if(ImGui.isItemHovered())ImGui.setTooltip("Remove weapon/class mode requirements from this action's button alternatives. Explicit LB/RB/LT/RT holds are kept. Save the profile afterwards.");
        }
        if(editSkill)note("Direct skills need distinct buttons or chords to avoid firing together.");
    }
    static function drawSwapTarget():Void {
        if(!ImGui.beginCombo("##swapTarget",swapCaption))return;
        var failure:Dynamic=null;
        try {
            ImGui.setNextItemWidth(240);
            if(ImGui.inputTextWithHint("##swapSearch","Find another action",swapSearch.bytes,swapSearch.size)){swapQuery=swapSearch.get().toLowerCase();swapDirty=true;}
            if(swapRows.length==0)ImGui.textDisabled("No other actions match.");
            ImGuiLists.forVisible(swapRows.length,swapIndexFn);
        }catch(e:Dynamic)failure=e;
        ImGui.endCombo();if(failure!=null)throw failure;
    }
    static function drawProfileTools():Void {
        UiChrome.centeredHeader("Profiles",38);UiChrome.gap(12);note(profileSummary);UiChrome.gap(12);
        ImGui.textDisabled("Profile name");ImGui.getContentRegionAvail(cardAvail);
        ImGui.setNextItemWidth(Math.max(100,cardAvail.x-152));
        if(ImGui.inputTextWithHint("##profileName","Name your layout",name.bytes,name.size)){nameDirty=true;confirmSave=false;}
        ImGui.sameLine(0,8);ImGui.beginDisabled(!canSave||draftAlternative>=0);var failure:Dynamic=null;
        try {
            if(UiChrome.accentButton(confirmSave?"Confirm save?###save":"Save profile###save",btnWide)){
                if(!saveExists||confirmSave){pendingSave=true;confirmSave=false;}else{confirmSave=true;confirmLoad=false;deleteName="";}
            }
        }catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
        UiChrome.gap(12);listSize.x=0;ImGui.getContentRegionAvail(cardAvail);listSize.y=Math.max(120,cardAvail.y-134);UiScope.child("##profiles",listSize,profilesFn);
        if(ghost(confirmLoad?"Confirm load?###load":"Load###load",btnMid,selectedProfile=="")){
            if(Remap.dirty&&!confirmLoad){confirmLoad=true;confirmSave=false;deleteName="";}else{pendingLoad=true;confirmLoad=false;}
        }
        ImGui.sameLine(0,6);
        if(ghost(deleteName==selectedProfile&&deleteName!=""?"Confirm delete?###deleteProfile":"Delete profile###deleteProfile",btnWide,selectedProfile=="")){
            if(deleteName==selectedProfile&&deleteName!=""){pendingDelete=deleteName;deleteName="";}else{deleteName=selectedProfile;confirmLoad=false;confirmSave=false;}
        }
        ImGui.sameLine(0,6);if(ghost("Refresh",btnMid))pendingRefresh=true;
        if(confirmSave)note("This name already exists. Confirm save will replace that profile.");
        if(confirmLoad)note("Loading replaces unsaved layout changes. Confirm load to continue.");
        if(deleteName!="")note("Delete the selected saved file? Your current bindings stay in memory.");
        if(confirmSave||confirmLoad||deleteName!="")if(ghost("Cancel##profileConfirm",btnMid)){confirmSave=false;confirmLoad=false;deleteName="";}
    }
    static var profilesFn:Void->Void=null;
    static function drawProfiles():Void {
        if(profileLabels.length==0){note("No saved profiles. Enter a name above and choose Save profile.");return;}
        ImGuiLists.forVisible(profileLabels.length,profileIndexFn);
    }
    static function drawProfileIndex(i:Int):Void {
        ImGui.pushID_Str(Remap.profiles[i]);var failure:Dynamic=null;
        try {
            if(ReleaseChrome.profileRow(profileLabels[i],Remap.profiles[i]==selectedProfile)){selectedProfile=Remap.profiles[i];confirmLoad=false;deleteName="";}
            if(ImGui.isItemHovered())ImGui.setTooltip(Remap.profiles[i]);
            BindingTools.profileContext(Remap.profiles[i]);
        }catch(e:Dynamic)failure=e;
        ImGui.popID();if(failure!=null)throw failure;
    }
    static function drawSwapIndex(i:Int):Void {
        var row=Remap.rows[swapRows[i]];ImGui.pushID_Str(row.id);var failure:Dynamic=null;
        try {
            if(ImGui.selectable(row.label,swapTarget==row.id)){swapTarget=row.id;swapDirty=true;}
            if(ImGui.isItemHovered())ImGui.setTooltip(row.id);
        }catch(e:Dynamic)failure=e;
        ImGui.popID();if(failure!=null)throw failure;
    }
    static function drawProfilesWindow():Void {
        if(ImGui.beginMenuBar()){if(UiMenus.item("Close panel"))profilesOpen.set(false);ImGui.endMenuBar();}
        ImGui.beginDisabled(Remap.pendingEdit!=null);var failure:Dynamic=null;
        try drawProfileTools()catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
    }
    static function drawLookupWindow():Void {
        if(ImGui.beginMenuBar()){if(UiMenus.item("Close panel"))lookupOpen.set(false);ImGui.endMenuBar();}
        BindingTools.drawFloatingLookup();
    }

    static function drawWindow():Void {
        BindingTools.menuBar();
        var headerY=ImGui.getCursorPosY();var headerX=ImGui.getCursorPosX();
        UiChrome.heading("Controller Remap",1.6);
        ImGui.getContentRegionAvail(avail);ImGui.setCursorPosY(headerY);
        ImGui.setCursorPosX(headerX+avail.x-btnWide.x);
        ImGui.beginDisabled(Remap.pendingEdit!=null);var restoreFailure:Dynamic=null;
        try {
            if(ghost(confirmClear?"Confirm restore?###restore":"Restore all###restore",btnWide)){
                if(confirmClear){pendingClear=true;confirmClear=false;}else confirmClear=true;
            }
            if(ImGui.isItemHovered())ImGui.setTooltip("Restore all controller bindings. Saved profile files are kept.");
            if(confirmClear){
                ImGui.setCursorPosY(headerY);ImGui.setCursorPosX(headerX);
                if(ghost("Cancel##restore",btnMid))confirmClear=false;
            }
        }catch(e:Dynamic)restoreFailure=e;
        ImGui.endDisabled();if(restoreFailure!=null)throw restoreFailure;
        ImGui.setCursorPosX(headerX);ImGui.setCursorPosY(headerY+38);
        if(cursorLocked!=false)note("Open a game menu to free the cursor and edit. F10 closes this window.");
        if(Remap.applyFailed)coloredNote(Remap.status,ThemePalette.STATUS_DANGER);
        ImGui.getContentRegionAvail(avail);
        var leftW=Math.floor(avail.x*0.56);
        leftSize.x=leftW;leftSize.y=avail.y-4;rightSize.x=avail.x-leftW-8;rightSize.y=avail.y-4;
        UiChrome.celChild("##left",leftSize,leftFn);ImGui.sameLine(0,8);UiScope.child("##right",rightSize,rightFn);
        ConflictDialog.draw();
    }
    static function drawToolbar():Void {
        var startX=ImGui.getCursorPosX();ImGui.getContentRegionAvail(cardAvail);var width=cardAvail.x;
        if(ImGui.checkbox("Override native bindings##on",enabledRef))pendingEnable=enabledRef.get()?1:0;
        if(ImGui.isItemHovered())ImGui.setTooltip(Remap.status);
        ImGui.sameLine(0,16);ImGui.setCursorPosX(startX+width-ImGui.calcTextSize("Swap menu A / B").x-42);
        if(ImGui.checkbox("Swap menu A / B##swap",swapRef))pendingSwap=swapRef.get()?1:0;
        if(ImGui.isItemHovered())ImGui.setTooltip("Swap Confirm and Cancel in menus and aim confirmation only.");
    }
    static function drawStyledWindow():Void ReleaseChrome.styled(styledFn);
    static function drawThemedWindow():Void {
        var flags=cursorLocked==false?0:ImGuiWindowFlags.NoInputs;
        ToolWindow.drawMenuWindow(MAIN,open,mainBodyFn,flags);
        if(!open.get()){profilesOpen.set(false);lookupOpen.set(false);return;}
        ToolWindow.drawMenuWindow(PROFILES_WINDOW,profilesOpen,profilesWindowFn,flags);
        ToolWindow.drawMenuWindow(LOOKUP_WINDOW,lookupOpen,lookupWindowFn,flags);
    }
    static function frame():Void {
        try {
            var now=Sys.time();observeWindowInput(now);var wasOpen=open.get();
            open.set(windowInput.update(wasOpen,cursorLocked,gameHotkey||ImGui.isKeyPressed(ImGuiKey.F10,false),now));
            observe(now);
            var closeAfterDraw=wasOpen&&!open.get()&&(Remap.pendingEdit!=null||ConflictDialog.active());
            if(closeAfterDraw){Remap.cancelEdit();ConflictDialog.dismiss=true;open.set(true);}
            if(wasOpen&&!open.get())clearTransientState();if(!open.get())return;
            ThemePalette.wrap(windowFn);
            if(closeAfterDraw)open.set(false);
            if(!open.get())clearTransientState();
        }catch(e:Dynamic){var now=Sys.time();if(failedAt<0||now-failedAt>5){failedAt=now;trace("ControllerRemap error: "+Std.string(e));}}
    }
}
