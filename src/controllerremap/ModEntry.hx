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
import controllerremap.ui.PopupLifetime;

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
    static var editCaption="";static var editFamily="";static var swapCaption="Choose another action";static var swapPreview="";
    static var profileSummary="";
    static var editModeHint="";static var editSkill=false;static var pendingRemoveMode=false;
    static var canSave=false;static var saveExists=false;static var nameDirty=true;static var filterActive=false;
    static var bindingHeight:Single=352;static var profileHeight:Single=300;
    static var editorFocus=new EditorFocus();static var selectIntoEditor=false;
    static var focusRowIndex=0;static var pendingCategoryFocus=false;
    static var categoryFocusIndex=0;static var categoryAnchorIndex=0;
    static var legendSize:ImVec2;static var legendFn:Void->Void;
    static var banner:BannerArt;
    static var pendingSelectId="";static var pendingResolve=-1;static var draftAlternative=-1;
    static var scrollToEditor=false;static var scrollToProfiles=false;static var scrollToController=false;
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
    static var controller:ControllerInput;
    static var pointer=new ControllerPointer();
    static var pendingListen=-1;static var captureAction="";static var captureRevision=-1;
    static var listenSize:ImVec2;static var profileButton:ImVec2;
    static var nameMode="";static var nameSource="";static var pendingNameMode="";
    static var pendingRename="";static var pendingImport=false;static var pendingExport=false;
    static var profileCaption="Choose profile";static var controllerHint="";
    // queued clicks, handled in observe()
    static var pendingSelect=-1;static var pendingApply=false;static var pendingReset=false;static var pendingSave=false;
    static var pendingLoad=false;static var pendingRefresh=false;static var pendingClear=false;
    static var pendingEnable:Int=-1;static var pendingSwap:Int=-1;
    static var failedAt:Float=-1;

    static function main():Void {
        initUi();
        ImGui.register(HlxRuntime.moduleName(),frame);
    }
    static function initUi():Void {
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
        controller=new ControllerInput();listenSize=ImGui.vec2(90,30);profileButton=ImGui.vec2(104,30);
        legendSize=ImGui.vec2(0,62);legendFn=drawLegend;
        banner=new BannerArt();
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
        bindingFn=drawBindingCardBody;profileCardFn=drawProfileCardBody;controllerFn=drawControllerCard;
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
        banner.observe();
        Remap.poll(now);
        if(!Remap.ready) return;
        if(!profilesInitialized){
            profilesInitialized=true;selectedProfile=Remap.activeProfile;name.set(Remap.activeProfile);nameDirty=true;labelsDirty=true;
        }
        if(pendingListen>=0&&editId!=null&&Remap.pendingEdit==null){
            captureAction=editId;captureRevision=Remap.revision;controller.state.begin(pendingListen,now);pendingListen=-1;
        }
        if(controller.captured>=0){
            var slot=controller.state.slot;
            if(captureAction==editId&&captureRevision==Remap.revision&&slot>=0&&slot<editCount&&Remap.pendingEdit==null){
                padRef[slot].set(controller.captured);pendingApply=true;
            }
            captureAction="";
        }
        if(pendingNameMode!=""){
            nameMode=pendingNameMode;pendingNameMode="";nameSource=selectedProfile;
            if(nameMode=="rename")name.set(selectedProfile);
            else name.set(ProfileFiles.freeName("Layout",Remap.profiles));
            nameDirty=true;confirmSave=false;confirmLoad=false;deleteName="";
        }
        if(pendingRename!=""){
            if(Remap.renameProfile(nameSource,pendingRename)){
                selectedProfile=pendingRename;name.set(pendingRename);nameMode="";labelsDirty=true;
            }
            pendingRename="";nameDirty=true;
        }
        if(pendingImport){
            pendingImport=false;
            var imported=Remap.importProfile(Text.readClipboard());
            if(imported!=""){selectedProfile=imported;name.set(imported);nameMode="";nameDirty=true;labelsDirty=true;}
        }
        if(pendingExport){
            pendingExport=false;var json=Remap.exportProfile(selectedProfile);
            if(json!=null){ImGui.setClipboardText(json);Remap.status="Profile copied to clipboard.";}
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
        observeSelection();
        if(pendingSelectId!=""&&Remap.pendingEdit==null){
            for(row in Remap.rows)if(row.id==pendingSelectId){editId=row.id;syncEditor();ToolWindow.requestFocus(MAIN);focusSection(EditorFocus.EDITOR);controller.cancel();viewDirty=true;break;}
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
        if(pendingSave&&Remap.saveProfile(name.get())){selectedProfile=Remap.activeProfile;name.set(Remap.activeProfile);nameMode="";nameDirty=true;}
        if(pendingLoad&&selectedProfile!=""){Remap.loadProfile(selectedProfile);if(!Remap.dirty){name.set(Remap.activeProfile);nameDirty=true;}syncEditor();viewDirty=true;}
        if(pendingRefresh){Remap.listProfiles();}
        if(pendingDelete!=""){
            var deleted=pendingDelete;
            if(Remap.deleteProfile(deleted)){
                if(selectedProfile==deleted){selectedProfile="";nameMode="";}
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
        profileCaption=selectedProfile==""?"Choose profile":selectedProfile;
        controllerHint=controller.connected?controller.device:"Keyboard / mouse";
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
        refreshActionView();
        if(swapRevision!=Remap.revision){swapRevision=Remap.revision;swapDirty=true;}
        if(swapDirty){
            swapDirty=false;swapRows=[];
            for(i in 0...Remap.rows.length){var row=Remap.rows[i];if(row.id!=editId&&InputFamilies.same(editId,row.id)&&(swapQuery==""||row.id.toLowerCase().indexOf(swapQuery)>=0||row.label.toLowerCase().indexOf(swapQuery)>=0))swapRows.push(i);}
            swapCaption=swapTarget==""?"Choose another action":ActionLabels.display(swapTarget);
            swapPreview=swapTarget==""?"Select an action to exchange all of its controller bindings.":Remap.text(Remap.layoutPads(editId))+"  <->  "+Remap.text(Remap.layoutPads(swapTarget));
        }
        BindingTools.selectedAction=editId==null?"":editId;
        BindingTools.canSave=canSave&&draftAlternative<0;
        BindingTools.editorDraft=draftAlternative>=0;
        BindingTools.observe();ConflictDialog.observe();
    }

    static function syncEditor():Void {
        if(controller.state.listening)controller.cancel();captureAction="";
        if(editId==null) return;
        editCaption=ActionLabels.display(editId);editFamily=InputFamilies.label(editId);swapTarget="";swapQuery="";swapSearch.set("");swapDirty=true;
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
    }
    static function observeSelection():Void {
        if(pendingSelect>=0&&Remap.pendingEdit==null){
            var rows=Remap.rows;
            if(pendingSelect<view.length&&view[pendingSelect]<rows.length){
                selectedRow=pendingSelect;editId=rows[view[pendingSelect]].id;
                syncEditor();
                if(selectIntoEditor){focusSection(EditorFocus.EDITOR);controller.cancel();}
            }
            pendingSelect=-1;
        }
        selectIntoEditor=false;
    }
    static function refreshActionView():Void {
        if(!viewDirty)return;viewDirty=false;
        var q=filter.get().toLowerCase();filterActive=q!="";view=[];
        for(i in 0...Remap.rows.length){var r=Remap.rows[i];if(ActionGroups.matches(actionGroup,r.id,r.text,r.planned,q,r.label))view.push(i);}
        viewLabel=view.length+" of "+Remap.rows.length+" actions";selectedRow=-1;
        if(editId!=null)for(i in 0...view.length)if(Remap.rows[view[i]].id==editId)selectedRow=i;
        focusRowIndex=Std.int(Math.max(0,Math.min(focusRowIndex,view.length-1)));
        if(pendingCategoryFocus){pendingCategoryFocus=false;focusSection(view.length==0?EditorFocus.FILTERS:EditorFocus.ACTIONS);}
        else if(view.length==0&&editorFocus.pending==EditorFocus.ACTIONS)focusSection(EditorFocus.FILTERS);
    }
    static function changeCategory(direction:Int):Void {
        actionGroup=(actionGroup+(direction<0?-1:1)+ActionGroups.labels.length)%ActionGroups.labels.length;
        viewDirty=true;focusRowIndex=0;
        focusSection(editorFocus.current==EditorFocus.ACTIONS?EditorFocus.ACTIONS:EditorFocus.FILTERS);
    }
    static function removeEditorAlternative(index:Int):Void {
        for(k in index...editCount-1){padRef[k].set(padRef[k+1].get());holdRef[k].set(holdRef[k+1].get());if(k+1<originalPads.length)originalPads[k]=originalPads[k+1];}
        editCount--;draftAlternative=-1;confirmSave=false;
    }
    static function clearTransientState():Void {
        controller.cancel();pendingListen=-1;captureAction="";pendingNameMode="";nameMode="";nameSource="";
        pendingRename="";pendingImport=false;pendingExport=false;Help.show=false;
        pendingSelect=-1;editId=null;editCount=0;selectedRow=-1;originalPads=[];focusRowIndex=0;pendingCategoryFocus=false;
        categoryFocusIndex=0;categoryAnchorIndex=0;
        confirmClear=false;confirmReset=false;confirmSave=false;confirmLoad=false;deleteName="";
        padFilter.set("");padQuery="";
        swapTarget="";swapQuery="";swapSearch.set("");swapDirty=true;pendingExchange="";
        editorFocus.reset();selectIntoEditor=false;scrollToController=false;ControllerView.focusFirst=false;PopupLifetime.closing=false;
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
        ImGui.beginDisabled(disabled||PopupLifetime.closing);var result=false;var failure:Dynamic=null;
        try result=UiChrome.ghostButton(label,size)catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;return result;
    }
    static function combo(id:String,ref:IntRef,options:Array<String>):Void {
        var current=ref.get();if(current>=options.length){current=0;ref.set(0);}
        if(!ImGui.beginCombo(id,current<0?"Existing combined hold":options[current]))return;
        var failure:Dynamic=null;
        try {
            if(!PopupLifetime.dismiss()){
                if(options==Remap.PADS){
                    ImGui.setNextItemWidth(180);
                    if(ImGui.inputTextWithHint("##buttonFilter","Find button",padFilter.bytes,padFilter.size))padQuery=padFilter.get().toLowerCase();
                }
                var query=options==Remap.PADS?padQuery:"";var matches=0;
                for(k in 0...options.length){
                    if(query!=""&&padSearch[k].indexOf(query)<0)continue;
                    matches++;ImGui.pushID_Int(k);var error:Dynamic=null;var picked=false;
                    try {
                        picked=ImGui.selectable(options[k],k==current);
                        if(k==current||(matches==1&&(current<0||(query!=""&&padSearch[current].indexOf(query)<0))))ImGui.setItemDefaultFocus();
                    }catch(e:Dynamic)error=e;
                    ImGui.popID();if(error!=null)throw error;
                    if(picked){ref.set(k);pendingApply=true;confirmSave=false;}
                }
                if(matches==0)ImGui.textDisabled("No matching buttons.");
            }
            ControllerScroll.apply();
        }catch(e:Dynamic)failure=e;
        ImGui.endCombo();if(failure!=null)throw failure;
    }
    static function drawLeft():Void {
        if(editorFocus.pending==EditorFocus.FILTERS||editorFocus.pending==EditorFocus.OPTIONS)ImGui.setScrollY(0);
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
            if(i==categoryAnchorIndex&&editorFocus.consume(EditorFocus.FILTERS))ImGui.setKeyboardFocusHere();
            if(UiChrome.navButton(ActionGroups.labels[i],actionGroup==i,groupButton)){
                actionGroup=i;viewDirty=true;focusRowIndex=0;pendingCategoryFocus=controller.state.navigation&&ImGui.isItemFocused();
                if(pendingCategoryFocus)controller.cancel();
            }
            if(ImGui.isItemFocused()){editorFocus.mark(EditorFocus.FILTERS);categoryFocusIndex=i;}
            if(controller.state.navigation&&ImGui.isItemFocused()){
                var target=i,leave=-1,pressed=false;
                if(ImGui.isKeyPressed(ImGuiKey.DownArrow,false)){
                    pressed=true;var nextRow=(Std.int(i/columns)+1)*columns;
                    if(nextRow>=ActionGroups.labels.length)leave=EditorFocus.OPTIONS;
                    else {
                        var nextCount=Std.int(Math.min(columns,ActionGroups.labels.length-nextRow));
                        target=nextRow+Std.int(Math.min(nextCount-1,Math.floor((column+0.5)*nextCount/inRow)));
                    }
                }else if(ImGui.isKeyPressed(ImGuiKey.UpArrow,false)){
                    pressed=true;var previousRow=(Std.int(i/columns)-1)*columns;
                    if(previousRow<0)leave=EditorFocus.WINDOW;
                    else target=previousRow+Std.int(Math.min(columns-1,Math.floor((column+0.5)*columns/inRow)));
                }else if(ImGui.isKeyPressed(ImGuiKey.LeftArrow,false)){pressed=true;if(column>0)target=i-1;}
                else if(ImGui.isKeyPressed(ImGuiKey.RightArrow,false)){pressed=true;if(column+1<inRow)target=i+1;}
                if(pressed){
                    focusSection(leave>=0?leave:EditorFocus.FILTERS);
                    if(leave<0)categoryAnchorIndex=target;
                    controller.cancel();
                }
            }
            if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(ActionGroups.descriptions[i]);
        }
        UiChrome.gap(8);
        ImGui.beginDisabled(Remap.pendingEdit!=null||PopupLifetime.closing);var toggleFailure:Dynamic=null;
        try drawToolbar()catch(e:Dynamic)toggleFailure=e;
        ImGui.endDisabled();if(toggleFailure!=null)throw toggleFailure;
        UiChrome.gap(8);
        ImGui.getContentRegionAvail(cardAvail);ImGui.setNextItemWidth(Math.max(100,cardAvail.x-152));
        if(ImGui.inputTextWithHint("##filter","Search actions or bindings",filter.bytes,filter.size))viewDirty=true;
        if(ImGui.isItemFocused())editorFocus.mark(EditorFocus.OPTIONS);
        ImGui.sameLine(0,8);
        if(ghost("Clear##filter",clearSize,!filterActive&&actionGroup==0)){filter.set("");actionGroup=0;viewDirty=true;}
        if(ImGui.isItemFocused()){
            editorFocus.mark(EditorFocus.OPTIONS);
            if(controller.state.navigation&&ImGui.isKeyPressed(ImGuiKey.DownArrow,false)){focusSection(EditorFocus.ACTIONS);controller.cancel();}
        }
        if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Clear the search and show all actions.");
        ImGui.textDisabled(viewLabel);ImGui.sameLine(0,12);ImGui.textDisabled(countLabel);
        ImGui.getContentRegionAvail(listSize);UiScope.child("##actionList",listSize,listFn);
        ControllerScroll.apply();
    }
    static function drawActionRows():Void {
        if(view.length==0){note("No actions match. LB/RB changes category; X/Y changes section.");if(editorFocus.consume(EditorFocus.ACTIONS))focusSection(EditorFocus.FILTERS);return;}
        UiScope.table("##actions",2,rowsFn,ImGuiTableFlags.SizingStretchProp|ImGuiTableFlags.BordersOuter|ImGuiTableFlags.BordersInnerH|ImGuiTableFlags.RowBg|ImGuiTableFlags.NoSavedSettings,zero,0);
        ControllerScroll.apply();
    }
    static var rowsFn:Void->Void=null;
    static function focusSection(section:Int):Void {
        editorFocus.request(section);
        if(section==EditorFocus.FILTERS)categoryAnchorIndex=actionGroup;
        if(section==EditorFocus.EDITOR)scrollToEditor=true;
        if(section==EditorFocus.PROFILES)scrollToProfiles=true;
        if(section==EditorFocus.CONTROLLER){scrollToController=true;ControllerView.focusFirst=true;}
    }
    static function drawControllerCard():Void {
        if(editorFocus.pending==EditorFocus.CONTROLLER){ImGui.setScrollHereY();editorFocus.consume(EditorFocus.CONTROLLER);}
        if(ImGui.isWindowFocused())editorFocus.mark(EditorFocus.CONTROLLER);
        BindingTools.drawControllerCard();
        ControllerScroll.apply();
    }
    static function drawRows():Void {
        ImGui.tableSetupColumn("Action",ImGuiTableColumnFlags.WidthStretch,0.48);
        ImGui.tableSetupColumn("Controller binding",ImGuiTableColumnFlags.WidthStretch,0.52);
        ImGui.tableHeadersRow();
        for(i in 0...view.length){
            var row=Remap.rows[view[i]];
            ImGui.tableNextRow();ImGui.tableSetColumnIndex(0);ImGui.pushID_Str(row.id);
            var failure:Dynamic=null;
            try {
                var focusRow=i==focusRowIndex;
                var requested=focusRow&&editorFocus.consume(EditorFocus.ACTIONS);
                if(requested)ImGui.setKeyboardFocusHere();
                var picked=ImGui.selectable(row.label,i==selectedRow,ImGuiSelectableFlags.SpanAllColumns,actionSize);
                var focused=ImGui.isItemFocused();
                if(requested)ImGui.setScrollHereY();
                if(focused){editorFocus.mark(EditorFocus.ACTIONS);focusRowIndex=i;}
                if(focused&&controller.state.navigation&&(ImGui.isKeyPressed(ImGuiKey.LeftArrow,false)||i==0&&ImGui.isKeyPressed(ImGuiKey.UpArrow,false)||i==view.length-1&&ImGui.isKeyPressed(ImGuiKey.DownArrow,false))){focusSection(EditorFocus.FILTERS);controller.cancel();}
                var enterEditor=focused&&controller.state.navigation&&(controller.down[0]||ImGui.isKeyPressed(ImGuiKey.RightArrow,false));
                if((picked||enterEditor)&&Remap.pendingEdit==null){pendingSelect=i;selectIntoEditor=enterEditor;}
                if(i==selectedRow||(selectedRow<0&&i==0))ImGui.setItemDefaultFocus();
                if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(row.id);
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
        if(scrollToController){ImGui.setScrollY(bindingHeight+profileHeight+24);scrollToController=false;}
        var cardFlags=ImGuiWindowFlags.NoScrollbar|ImGuiWindowFlags.NoScrollWithMouse;
        var autoHeight=imgui.Enums.ImGuiChildFlags.AutoResizeY|imgui.Enums.ImGuiChildFlags.AlwaysAutoResize;
        bindingSize.x=0;bindingSize.y=0;
        UiChrome.celChild("##bindingCard",bindingSize,bindingFn,cardFlags,autoHeight);
        ImGui.getItemRectSize(bindingSize);bindingHeight=bindingSize.y;UiChrome.gap(8);
        profileSize.x=0;profileSize.y=0;
        UiChrome.celChild("##profileCard",profileSize,profileCardFn,cardFlags,autoHeight);
        ImGui.getItemRectSize(profileSize);profileHeight=profileSize.y;UiChrome.gap(8);
        controllerSize.x=0;controllerSize.y=0;
        UiChrome.celChild("##controllerCard",controllerSize,controllerFn,cardFlags,autoHeight);
        ControllerScroll.apply();
    }
    static function drawBindingCardBody():Void {
        ImGui.setScrollY(0);
        if(ImGui.isWindowFocused())editorFocus.mark(EditorFocus.EDITOR);
        drawBinding();
        ControllerScroll.apply();
    }
    static function drawProfileCardBody():Void {
        ImGui.setScrollY(0);
        if(ImGui.isWindowFocused())editorFocus.mark(EditorFocus.PROFILES);
        UiChrome.centeredHeader("Profiles",38);UiChrome.gap(8);
        drawProfileControls();
        ControllerScroll.apply();
    }
    static function drawBinding():Void {
        UiChrome.centeredHeader("Edit bindings",38);UiChrome.gap(12);
        if(editId==null){note("Select an action.");return;}
        UiChrome.subHeader(editCaption);if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(editId);
        note(editFamily);
        drawBindingFields();
        if(Remap.pendingEdit!=null){coloredNote("Resolve the binding conflict in the warning dialog.",ThemePalette.STATUS_DANGER);return;}
        UiChrome.gap(8);UiChrome.subHeader("Swap with another action");
        ImGui.getContentRegionAvail(cardAvail);ImGui.setNextItemWidth(Math.max(100,cardAvail.x-152));
        drawSwapTarget();ImGui.sameLine(0,8);
        if(ghost("Swap bindings##exchange",btnWide,swapTarget==""))pendingExchange=swapTarget;
        if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Exchange all button alternatives and hold combinations between these actions. Swap again to reverse it.");
        if(Help.tooltips)note(swapPreview);
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
                if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Remove this button alternative.");
                var requested=i==0&&editorFocus.consume(EditorFocus.EDITOR);
                if(requested)ImGui.setKeyboardFocusHere();
                if(ghost("Listen##capture",listenSize,controller.state.listening||!controller.connected||Remap.pendingEdit!=null))pendingListen=i;
                if(requested)ImGui.setScrollHereY();
                if(ImGui.isItemFocused())editorFocus.mark(EditorFocus.EDITOR);
            }catch(e:Dynamic)failure=e;
            ImGui.popID();if(failure!=null)throw failure;
        }
        if(removeAt>=0){
            removeEditorAlternative(removeAt);pendingApply=true;
        }
        if(controller.state.listening){
            note(controller.state.message);
            if(ghost("Cancel listening##cancelCapture",btnMid))controller.cancel();
        }else if(controller.state.message!="")note(controller.state.message);
        if(Remap.bindAction==editId&&Remap.bindMessage!=""){
            coloredNote(Remap.bindMessage,Remap.bindState==1?ThemePalette.STATUS_SUCCESS:(Remap.bindState<0||Remap.bindState==3?ThemePalette.STATUS_DANGER:ThemePalette.STATUS_INFO));
        }
        ImGui.beginDisabled(Remap.pendingEdit!=null);var failure:Dynamic=null;
        try drawBindingActions()catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
    }
    static function drawBindingActions():Void {
        if(editCount==0)note("This action has no controller binding.");
        if(editCount==0&&editorFocus.consume(EditorFocus.EDITOR))ImGui.setKeyboardFocusHere();
        if(ghost("+ Add button",btnMid,editCount>=MAX_EDIT||draftAlternative>=0)){padRef[editCount].set(0);holdRef[editCount].set(0);draftAlternative=editCount;editCount++;confirmSave=false;Remap.clearBindNotice();focusSection(EditorFocus.EDITOR);controller.cancel();}
        ImGui.sameLine(0,6);
        if(ghost(confirmReset?"Confirm reset?###reset":"Reset action###reset",btnWide)){
            if(confirmReset){pendingReset=true;confirmReset=false;}else confirmReset=true;
        }
        if(Remap.applyFailed){UiChrome.gap(8);if(ghost("Retry apply",btnMid))pendingApply=true;}
        if(confirmReset)note("Click again to restore this action's original controller binding.");
        if(draftAlternative>=0)note("Choose a button or Listen.");
        if(editModeHint!=""){
            note(editModeHint);
            if(ghost("Remove mode hold##direct",btnWide))pendingRemoveMode=true;
            if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Remove weapon/class mode requirements from this action's button alternatives. Explicit LB/RB/LT/RT holds are kept. Save the profile afterwards.");
        }
        if(Help.show&&editSkill)note("Direct skills need distinct buttons or chords.");
    }
    static function drawSwapTarget():Void {
        if(!ImGui.beginCombo("##swapTarget",swapCaption))return;
        var failure:Dynamic=null;
        try {
            if(!PopupLifetime.dismiss()){
                ImGui.setNextItemWidth(240);
                if(ImGui.inputTextWithHint("##swapSearch","Find another action",swapSearch.bytes,swapSearch.size)){swapQuery=swapSearch.get().toLowerCase();swapDirty=true;}
                if(swapRows.length==0)ImGui.textDisabled("No other actions match.");
                ImGuiLists.forVisible(swapRows.length,swapIndexFn);
            }
            ControllerScroll.apply();
        }catch(e:Dynamic)failure=e;
        ImGui.endCombo();if(failure!=null)throw failure;
    }
    static function drawProfileTools():Void {
        UiChrome.centeredHeader("Profiles",38);UiChrome.gap(8);drawProfileControls();
    }
    static function drawProfileControls():Void {
        note(profileSummary);
        ImGui.beginDisabled(Remap.pendingEdit!=null||controller.state.listening);var failure:Dynamic=null;
        try {
            ImGui.setNextItemWidth(300);
            if(editorFocus.consume(EditorFocus.PROFILES))ImGui.setKeyboardFocusHere();
            if(ImGui.beginCombo("##profileSelect",profileCaption)){
                var error:Dynamic=null;
                try {
                    if(!PopupLifetime.dismiss())for(profile in Remap.profiles){
                        if(ImGui.selectable(profile,profile==selectedProfile)){
                            selectedProfile=profile;name.set(profile);nameDirty=true;nameMode="";confirmLoad=false;confirmSave=false;deleteName="";
                        }
                        if(profile==selectedProfile)ImGui.setItemDefaultFocus();
                    }
                    ControllerScroll.apply();
                }catch(e:Dynamic)error=e;
                ImGui.endCombo();if(error!=null)throw error;
            }
            if(ghost(confirmLoad?"Confirm load###quickLoad":"Load###quickLoad",profileButton,selectedProfile=="")){
                if(Remap.dirty&&!confirmLoad){confirmLoad=true;confirmSave=false;deleteName="";}else{pendingLoad=true;confirmLoad=false;}
            }
            ImGui.sameLine(0,6);
            if(ghost(confirmSave?"Confirm save###quickSave":"Save###quickSave",profileButton,!canSave||draftAlternative>=0||nameMode!="")){
                if(saveExists&&!confirmSave){confirmSave=true;confirmLoad=false;deleteName="";}else{pendingSave=true;confirmSave=false;}
            }
            UiChrome.gap(4);
            if(ghost("New##quickNew",profileButton))pendingNameMode="new";
            ImGui.sameLine(0,6);if(ghost("Rename##quickRename",profileButton,selectedProfile==""))pendingNameMode="rename";
            ImGui.sameLine(0,6);
            if(ghost(deleteName==selectedProfile&&deleteName!=""?"Confirm erase###quickErase":"Erase###quickErase",profileButton,selectedProfile=="")){
                if(deleteName==selectedProfile&&deleteName!=""){pendingDelete=deleteName;deleteName="";}else{deleteName=selectedProfile;confirmLoad=false;confirmSave=false;}
            }
            UiChrome.gap(4);
            if(ghost("Import##quickImport",profileButton))pendingImport=true;
            ImGui.sameLine(0,6);if(ghost("Export##quickExport",profileButton,selectedProfile==""))pendingExport=true;
            if(nameMode!=""){
                ImGui.setNextItemWidth(300);
                if(ImGui.inputTextWithHint("##quickName","Profile name",name.bytes,name.size)){nameDirty=true;confirmSave=false;}
                if(nameMode=="new"&&saveExists)note("Name already exists.");
                if(ghost(nameMode=="rename"?"Apply name##nameApply":"Create##nameApply",profileButton,!canSave||(nameMode=="new"&&saveExists))){
                    if(nameMode=="rename")pendingRename=name.get();else pendingSave=true;
                }
                ImGui.sameLine(0,6);if(ghost("Cancel##nameCancel",profileButton)){nameMode="";name.set(selectedProfile);nameDirty=true;}
            }
            if(confirmSave||confirmLoad||deleteName!=""){
                if(ghost("Cancel##profileConfirm",profileButton)){confirmSave=false;confirmLoad=false;deleteName="";}
            }
        }catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
        if(Remap.status!="Starting...")note(Remap.status);
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
            if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(Remap.profiles[i]);
            BindingTools.profileContext(Remap.profiles[i]);
        }catch(e:Dynamic)failure=e;
        ImGui.popID();if(failure!=null)throw failure;
    }
    static function drawSwapIndex(i:Int):Void {
        var row=Remap.rows[swapRows[i]];ImGui.pushID_Str(row.id);var failure:Dynamic=null;
        try {
            if(ImGui.selectable(row.label,swapTarget==row.id)){swapTarget=row.id;swapDirty=true;}
            if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(row.id);
        }catch(e:Dynamic)failure=e;
        ImGui.popID();if(failure!=null)throw failure;
    }
    static function drawProfilesWindow():Void {
        if(ImGui.beginMenuBar()){if(UiMenus.item("Close panel"))profilesOpen.set(false);ImGui.endMenuBar();}
        ImGui.beginDisabled(Remap.pendingEdit!=null);var failure:Dynamic=null;
        try drawProfileTools()catch(e:Dynamic)failure=e;
        ImGui.endDisabled();if(failure!=null)throw failure;
        ControllerScroll.apply();
    }
    static function drawLookupWindow():Void {
        if(ImGui.beginMenuBar()){if(UiMenus.item("Close panel"))lookupOpen.set(false);ImGui.endMenuBar();}
        BindingTools.drawFloatingLookup();
        ControllerScroll.apply();
    }

    static function drawWindow():Void {
        recoverControllerFocus();
        BindingTools.menuBar();
        var headerY=ImGui.getCursorPosY();var headerX=ImGui.getCursorPosX();
        ImGui.getContentRegionAvail(avail);var headerWidth=avail.x;
        var bannerWidth=Math.max(1,Math.min(300,headerWidth-btnWide.x-24));
        ImGui.setCursorPosX(headerX+(headerWidth-bannerWidth)*0.5);banner.draw(bannerWidth);
        var headerHeight=banner.size.y;
        ImGui.setCursorPosY(headerY+(headerHeight-30)*0.5);
        ImGui.setCursorPosX(headerX+headerWidth-btnWide.x);
        ImGui.beginDisabled(Remap.pendingEdit!=null);var restoreFailure:Dynamic=null;
        try {
            if(editorFocus.consume(EditorFocus.WINDOW))ImGui.setKeyboardFocusHere();
            if(ghost(confirmClear?"Confirm restore?###restore":"Restore all###restore",btnWide)){
                if(confirmClear){pendingClear=true;confirmClear=false;}else confirmClear=true;
            }
            if(ImGui.isItemFocused()){
                editorFocus.mark(EditorFocus.WINDOW);
                if(controller.state.navigation&&ImGui.isKeyPressed(ImGuiKey.DownArrow,false)){focusSection(EditorFocus.FILTERS);controller.cancel();}
            }
            if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Restore all controller bindings. Saved profile files are kept.");
            if(confirmClear){
                ImGui.setCursorPosY(headerY+(headerHeight-30)*0.5);ImGui.setCursorPosX(headerX+headerWidth-btnWide.x-btnMid.x-8);
                if(ghost("Cancel##restore",btnMid))confirmClear=false;
            }
        }catch(e:Dynamic)restoreFailure=e;
        ImGui.endDisabled();if(restoreFailure!=null)throw restoreFailure;
        ImGui.setCursorPosX(headerX);ImGui.setCursorPosY(headerY+headerHeight+6);
        note(controllerHint);
        if(controller.supportIssue!="")note(controller.supportIssue);
        if(Help.show){
            note("D-pad / left stick: move. Right stick: scroll. A: select. B: back. LB / RB: category. X / Y: section.");
            note("F10 or hold LT + RT + RB and press A: open / close. Back + Start also works.");
            note("Alt: show the mouse pointer. Fresh controller input: hide it again.");
            note("Listen waits for release, then reads your next button. Holds stay as selected. Esc cancels.");
            note("Import reads profile JSON from the clipboard. Export copies the selected saved profile.");
        }
        if(Remap.applyFailed)coloredNote(Remap.status,ThemePalette.STATUS_DANGER);
        ImGui.getContentRegionAvail(avail);
        var leftW=Math.floor(avail.x*0.56);
        leftSize.x=leftW;leftSize.y=Math.max(80,avail.y-74);rightSize.x=avail.x-leftW-8;rightSize.y=leftSize.y;
        UiChrome.celChild("##left",leftSize,leftFn);ImGui.sameLine(0,8);UiScope.child("##right",rightSize,rightFn);
        UiChrome.gap(6);UiScope.child("##controllerLegend",legendSize,legendFn,0,ImGuiWindowFlags.NoScrollbar|ImGuiWindowFlags.NoNav);
        ControllerScroll.apply();
        ConflictDialog.controllerNavigation=pointer.hidden&&controller.connected&&controller.focused&&controller.state.navigation;
        ConflictDialog.draw();
        if(ConflictDialog.focusRecovered)controller.cancel();
    }
    static function drawLegend():Void {
        var popup=ImGui.isPopupOpen("",imgui.Enums.ImGuiPopupFlags.AnyPopupId|imgui.Enums.ImGuiPopupFlags.AnyPopupLevel);
        note(ControllerLegend.text(editorFocus.current,controller.state.listening,Remap.pendingEdit!=null||ConflictDialog.active(),popup));
        note(ControllerLegend.footer(controller.state.listening,popup));
    }
    static function recoverControllerFocus():Void {
        if(PopupLifetime.closing||ToolWindow.otherFocused(MAIN))return;
        if(!controller.connected||!controller.focused||!controller.state.navigation||Remap.pendingEdit!=null||ConflictDialog.active())return;
        if(ImGui.isPopupOpen("",imgui.Enums.ImGuiPopupFlags.AnyPopupId|imgui.Enums.ImGuiPopupFlags.AnyPopupLevel))return;
        var active=pointer.hidden||controller.state.used;
        if(!active)return;
        var focused=ImGui.isWindowFocused(imgui.Enums.ImGuiFocusedFlags.RootAndChildWindows);
        if(focused&&ImGui.isAnyItemFocused())return;
        ImGui.setWindowFocus();
        if(editorFocus.pending<0)focusSection(editorFocus.current);
        // Reclaim focus first; the recovering A must not also activate a control.
        controller.cancel();
    }
    static function drawToolbar():Void {
        var startX=ImGui.getCursorPosX();ImGui.getContentRegionAvail(cardAvail);var width=cardAvail.x;
        if(editorFocus.consume(EditorFocus.OPTIONS))ImGui.setKeyboardFocusHere();
        if(ImGui.checkbox("Override native bindings##on",enabledRef))pendingEnable=enabledRef.get()?1:0;
        if(ImGui.isItemFocused()){
            editorFocus.mark(EditorFocus.OPTIONS);
            if(controller.state.navigation&&ImGui.isKeyPressed(ImGuiKey.UpArrow,false)){focusSection(EditorFocus.FILTERS);controller.cancel();}
        }
        if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip(Remap.status);
        ImGui.sameLine(0,16);ImGui.setCursorPosX(startX+width-ImGui.calcTextSize("Swap menu A / B").x-42);
        if(ImGui.checkbox("Swap menu A / B##swap",swapRef))pendingSwap=swapRef.get()?1:0;
        if(ImGui.isItemFocused())editorFocus.mark(EditorFocus.OPTIONS);
        if(Help.tooltips&&ImGui.isItemHovered())ImGui.setTooltip("Swap Confirm and Cancel in menus and aim confirmation only.");
    }
    static function drawStyledWindow():Void ReleaseChrome.styled(styledFn);
    static function drawThemedWindow():Void {
        if(pointer.hidden&&controller.connected&&controller.focused)ImGui.setNavCursorVisible(true);
        var flags=cursorLocked==false&&!pointer.hidden?0:ImGuiWindowFlags.NoMouseInputs;
        ToolWindow.drawMenuWindow(MAIN,open,mainBodyFn,flags);
        if(!open.get()){profilesOpen.set(false);lookupOpen.set(false);return;}
        ToolWindow.drawMenuWindow(PROFILES_WINDOW,profilesOpen,profilesWindowFn,flags);
        ToolWindow.drawMenuWindow(LOOKUP_WINDOW,lookupOpen,lookupWindowFn,flags);
    }
    static function observeNavigation():Void {
        if(!open.get()||Remap.pendingEdit!=null||ConflictDialog.active()||ImGui.isPopupOpen("",imgui.Enums.ImGuiPopupFlags.AnyPopupId|imgui.Enums.ImGuiPopupFlags.AnyPopupLevel))return;
        if(controller.state.regionDirection!=0){
            editorFocus.move(controller.state.regionDirection,editId!=null,view.length>0);focusSection(editorFocus.current);controller.cancel();
        }else if(controller.state.paneDirection!=0){
            if(editorFocus.current==EditorFocus.ACTIONS||editorFocus.current==EditorFocus.FILTERS)changeCategory(controller.state.paneDirection);
            else {editorFocus.move(controller.state.paneDirection,editId!=null,view.length>0);focusSection(editorFocus.current);}
            controller.cancel();
        }else if(controller.state.back){
            var current=editorFocus.current;
            focusSection(current==EditorFocus.ACTIONS||current==EditorFocus.OPTIONS||current==EditorFocus.WINDOW?EditorFocus.FILTERS:(current==EditorFocus.FILTERS&&view.length==0?EditorFocus.WINDOW:EditorFocus.ACTIONS));
            controller.cancel();
        }
    }
    static function observeWindowCommand(wasOpen:Bool,now:Float):Void {
        open.set(windowInput.update(wasOpen,cursorLocked,gameHotkey||ImGui.isKeyPressed(ImGuiKey.F10,false)||controller.state.toggle,now));
        if(!wasOpen&&open.get()){ToolWindow.requestFocus(MAIN);editorFocus.request(EditorFocus.ACTIONS);}
        var mouseUsed=ImGui.isKeyPressed(ImGuiKey.LeftAlt,false)||ImGui.isKeyPressed(ImGuiKey.RightAlt,false)||ImGui.isMouseClicked(0)||ImGui.isMouseClicked(1)||ImGui.isMouseClicked(2);
        var wasHidden=pointer.hidden;
        pointer.update(open.get(),controller.connected,controller.focused,!wasOpen&&open.get(),controller.state.used,mouseUsed);
        if(wasOpen&&open.get()&&!wasHidden&&pointer.hidden){ToolWindow.requestFocus(MAIN);focusSection(editorFocus.current);controller.cancel();}
    }
    static function drawUiFrame(wasOpen:Bool):Void {
        // Keep the old controls alive for one final frame to close their native popups.
        var closing=wasOpen&&!open.get();
        if(closing){Remap.cancelEdit();ConflictDialog.dismiss=true;PopupLifetime.closing=true;open.set(true);}
        if(!open.get())return;
        ControllerScroll.begin(controller.connected&&controller.focused&&controller.state.navigation?controller.state.scrollY:0);
        var failure:Dynamic=null;
        try ThemePalette.wrap(windowFn)catch(e:Dynamic)failure=e;
        if(closing)open.set(false);
        PopupLifetime.closing=false;
        if(!open.get())clearTransientState();
        if(failure!=null)throw failure;
    }
    static function frame():Void {
        try {
            var now=Sys.time();observeWindowInput(now);var wasOpen=open.get();
            controller.sample(now,wasOpen);
            if(controller.state.listening&&ImGui.isKeyPressed(ImGuiKey.Escape,false))controller.cancel();
            observeWindowCommand(wasOpen,now);
            observeNavigation();
            observe(now);
            // Refresh native leases first. Queue button events only after UI focus recovery.
            controller.route(open.get(),cursorLocked==false,false,pointer.hidden);
            drawUiFrame(wasOpen);
            controller.route(open.get(),cursorLocked==false,true,pointer.hidden);
        }catch(e:Dynamic){try{controller.cancel();controller.route(false,cursorLocked==false);}catch(_:Dynamic){}var now=Sys.time();if(failedAt<0||now-failedAt>5){failedAt=now;trace("ControllerRemap error: "+Std.string(e));}}
    }
}
