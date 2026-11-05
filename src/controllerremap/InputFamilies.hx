package controllerremap;

/** Conflict families follow action consumers, not the keymap catalogue's display groups.
 * Source snapshot: evidence/input-families-5133f323.json. NoConflict is the engine's bit 1.
 */
class InputFamilies {
    static var groups:Map<String,Int>=new Map();
    static var known:Map<String,Bool>=new Map();
    static var flags:Map<String,Int>=new Map();
    static var initialized=false;
    static var catalog:Array<String>=[
    "ToggleAutoForward;MoveForward;MoveLeft;MoveBack;MoveRight;Sprint;Jump;Attack;Secondary;SignatureSkill;WeaponMode;WeaponSkill1;WeaponSkill2;WeaponSkill3;WeaponSkill4;GroupSkill1;ClassMode;Skill1;Skill2;Skill3;Skill4;Dash;LockTarget;AimSkillConfirm;AimSkillCancel;DrawWeapon;Consumable1;Consumable2;Consumable3;Consumable4;Interact;SeeDetails;Respawn;CloseWindow;OpenPauseMenu;FreeCursor;FreeCursorRotate;OpenChat;CloseChat;ContextualSkill;Mount;SpectateNext",
    "OpenCharacterCreator;OpenCharacterWindow;OpenJobWindow;OpenCodexWindow;OpenInventory;OpenMapWindow;OpenAchievement;OpenCollection;OpenSocial;OpenWindowWheel;OpenEmoteWheel;OpenNotification;DialogConfirm;UILeft;UIRight;Magnifier;Menu_LeftClick;Menu_RightClick;Menu_Shortcut;Menu_Back;UseFloatingCursor;Menu_TabNext;Menu_TabPrev;Menu_Confirm;Menu_Inspect;Map_ZoomIn;Map_ZoomOut;Map_InspectFilters;Map_InspectActivities;Skip_Cinematic",
    "Fullscreen;FullscreenEditor;ToggleUI;ToggleMusic;ToggleSound;ForceReload;ForceReloadLevel;Paste;FlyMode;DevPrefs;UnitSpawner;ConsoleCommands;Editor_SwitchMode;LocomotionDebug;LocomotionDebugClear;SavePos;LoadPos;SceneInspector;BatchInspector;PerfsStats;PerfHelpers;Editor_MoveFaster;RepeatCommand;ShortcutConsole0;ShortcutConsole1;ShortcutConsole2;ShortcutConsole3;ShortcutConsole4;ShortcutConsole5;ShortcutConsole6;ShortcutConsole7;ShortcutConsole8;ShortcutConsole9",
    "ToggleUITrailer;ShortcutTrailer0;ShortcutTrailer1;ShortcutTrailer2;ShortcutTrailer3;ShortcutTrailer4;ShortcutTrailer5;ShortcutTrailer6;ShortcutTrailer7;ShortcutTrailer8;ShortcutTrailer9;ShortcutTrailer10;ShortcutTrailer11;CinMoveSpeedIncrease;CinMoveSpeedDecrease;CinHeightSpeedIncrease;CinHeightSpeedDecrease;CinRotateSpeedIncrease;CinRotateSpeedDecrease;CinFovIncrease;CinFovDecrease",
    "LeftClick;MouseBack;MouseForward;CtrlLeftClick;ShiftLeftClick;RightClick;CtrlRightClick;ShiftRightClick;MiddleClick;Pad_LB;Pad_RB;Pad_LT;Pad_RT;Pad_Y;Pad_X;Pad_Back;Pad_dpad_left;Pad_dpad_right;Pad_L3;Pad_R3"
];
    static function init():Void {
        if(initialized)return;initialized=true;
        for(g in 0...catalog.length)for(id in catalog[g].split(";")){groups.set(id,g);known.set(id,true);}
        for(id in ["SeeDetails","Respawn","FreeCursorRotate","Skip_Cinematic"])flags.set(id,1);
    }
    public static function record(id:String,nativeFlags:Int,group:Int):Void {
        init();flags.set(id,nativeFlags);groups.set(id,group);
    }
    public static function protectedSharing(id:String):Bool {init();return flags.exists(id)&&(flags.get(id)&1)!=0;}
    public static function family(id:String):String {
        init();if(id==null)return "unknown:";
        if(["Walk","Crouch","Dodge","Roll","MoveBack","UseItem","Loot","PickUp"].indexOf(id)>=0)return "gameplay";
        if(!known.exists(id))return "unknown:"+id;
        if(id=="Respawn"||id=="SpectateNext")return "death";
        if(StringTools.startsWith(id,"AimSkill"))return "aim";
        if(StringTools.startsWith(id,"Map_"))return "map";
        if(id=="DialogConfirm")return "dialog";
        if(id=="CloseChat")return "chat";
        if(StringTools.startsWith(id,"Menu_")||["CloseWindow","SeeDetails","UILeft","UIRight","UseFloatingCursor"].indexOf(id)>=0)return "menu";
        var group=groups.get(id);
        if(group==4||StringTools.startsWith(id,"Pad_")||StringTools.startsWith(id,"RawPad"))return "raw:"+id;
        if(group==3)return "trailer";
        if(group==2)return "system";
        if(ActionGroups.of(id)==5||id=="FreeCursorRotate")return "camera";
        // Opening a window is still a gameplay shortcut; the catalogue label "UIs" is not a gate.
        if(group==0||group==1)return "gameplay";
        return "unknown:"+id;
    }
    public static function same(left:String,right:String):Bool return family(left)==family(right);
    public static function conflicts(left:String,right:String):Bool return same(left,right)&&!protectedSharing(left)&&!protectedSharing(right);
    public static function label(id:String):String return switch(family(id)){
        case "gameplay":"Gameplay";case "death":"Death / respawn";case "aim":"Skill aiming";
        case "menu":"Menu navigation";case "map":"Map";case "dialog":"Dialog";case "chat":"Chat";
        case "camera":"Camera";case "system":"System";case "trailer":"Trailer";
        default:"Independent action";
    };
}
