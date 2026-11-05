package controllerremap;

class CursorNative {
    @:hlNative("?sfcursor","mouse_guard_client") public static function guard(owner:hl.Bytes,enabled:Bool):Int return -9;
    @:hlNative("?sfcursor","input_policy_client") public static function policy(owner:hl.Bytes,available:Bool,free:Bool,interactive:Bool):Int return -9;
    @:hlNative("?sfcursor","sync_confinement") public static function confinement(confined:Bool):Int return -9;
    @:hlNative("?sfcursor","cursor_visibility_client") public static function pointer(owner:hl.Bytes,hidden:Bool):Int return -9;
}

/** Observe-owned controller adapter. Uses Farever's connected device/config, including Steam's virtual pad. */
class ControllerInput {
    public var state(default,null)=new ControllerState();
    public var connected(default,null)=false;
    public var focused(default,null)=false;
    public var device(default,null)="No controller";
    public var captured(default,null)=-1;
    public var guardStatus(default,null)=0;
    public var pointerStatus(default,null)=0;
    public var policyStatus(default,null)=0;
    public var supportIssue(default,null)="";
    public var down(default,null):Array<Bool>=[for(_ in 0...24)false];
    var codes:Array<Int>=[for(_ in 0...16)-1];
    var navigation:ControllerNavigation;
    public var navigationStatus(get,never):Int;
    function get_navigationStatus():Int return navigation.status;
    var owner:hl.Bytes;
    var hasGuard=false;var hasPolicy=false;var hasConfinement=false;
    var hasPointer=false;
    var helperReady=false;
    var index=-1;
    var focusLease:InputFocusLease;
    var windowGetter:hlx.runtime.ResolvedMember;
    var focusGetter:hlx.runtime.ResolvedMember;
    var noArgs:Array<Dynamic>=[];
    var focusArgs:Array<Dynamic>=[null];
    public function new(){
        owner=@:privateAccess "controllerremap".toUtf8();
        navigation=new ControllerNavigation(owner);
        hasGuard=hl.Api.isPrimLoaded(CursorNative.guard);
        hasPolicy=hl.Api.isPrimLoaded(CursorNative.policy);
        hasConfinement=hl.Api.isPrimLoaded(CursorNative.confinement);
        hasPointer=hl.Api.isPrimLoaded(CursorNative.pointer);
        helperReady=hasGuard&&hasPolicy&&hasConfinement&&hasPointer&&hl.Api.isPrimLoaded(ControllerNavigation.configure);
        if(!helperReady)
            supportIssue="SFCursor is missing or outdated. Extract the full ControllerRemap ZIP into Farever, then restart.";
        focusLease=new InputFocusLease(readGameFocus,writeGameFocus);
    }
    function axis(i:Int,value:Float):Void down[i]=Math.isFinite(value)&&value>=(down[i]?0.35:0.65);
    public function sample(now:Float,editing:Bool):Void {
        connected=false;focused=false;captured=-1;
        try {
            if(windowGetter==null)windowGetter=HlxRuntime.resolveStaticMember(HlxRuntime.resolveType("hxd.Window"),"getInstance");
            if(focusGetter==null)focusGetter=HlxRuntime.resolveMember(HlxRuntime.resolveType("hxd.Window"),"get_isFocused");
            var window=HlxRuntime.callResolved(windowGetter,noArgs);
            focusArgs[0]=window;focused=window!=null&&HlxRuntime.callResolved(focusGetter,focusArgs)==true;focusArgs[0]=null;
            var pad=gamepad.Pad.inst;
            if(pad!=null&&pad.connected){
                connected=true;
                var c=pad.config;
                if(c==null)throw "Controller configuration unavailable";
                // Refresh config for hotplug/Steam mapping changes; no controller enum ordinals are assumed.
                codes[0]=c.A;codes[1]=c.B;codes[2]=c.X;codes[3]=c.Y;
                codes[4]=c.LB;codes[5]=c.RB;codes[6]=c.LT;codes[7]=c.RT;
                codes[8]=c.back;codes[9]=c.start;codes[10]=c.analogClick;codes[11]=c.ranalogClick;
                codes[12]=c.dpadUp;codes[13]=c.dpadDown;codes[14]=c.dpadLeft;codes[15]=c.dpadRight;
                // hxd.Pad.isDown reads this same bool array; direct reads avoid per-button argument arrays.
                var buttons=pad.buttons;
                for(i in 0...16)down[i]=buttons!=null&&codes[i]>=0&&codes[i]<buttons.length&&buttons.getDyn(codes[i])==true;
                var x=pad.rawXAxis,y=pad.rawYAxis,rx=pad.rawRXAxis,ry=pad.rawRYAxis;
                axis(16,-y);axis(17,y);axis(18,-x);axis(19,x);
                axis(20,-ry);axis(21,ry);axis(22,-rx);axis(23,rx);
                if(index!=pad.index){index=pad.index;device=pad.get_name();state.cancel();}
            }
        }catch(_:Dynamic){connected=false;focusArgs[0]=null;}
        if(!connected){for(i in 0...24)down[i]=false;index=-1;device="No controller";}
        captured=state.update(down,connected,focused,editing,now);
    }
    /** The game's pad-active gate is distinct from the raw hxd.Pad reads above. */
    static function readGameFocus():Bool return gamepad.Pad.hasFocus;
    static function writeGameFocus(value:Bool):Void gamepad.Pad.hasFocus=value;
    public function route(active:Bool,free:Bool,submitEvents:Bool=true,hidePointer:Bool=false):Void {
        var owns=active&&focused;
        var held=false;for(value in down)held=held||value;
        navigation.route(down,owns,state.navigation,submitEvents);
        try focusLease.update(owns&&connected&&navigation.status==1,focused,connected&&held)catch(_:Dynamic){}
        var mouseFree=free&&!hidePointer;
        try guardStatus=hasGuard?CursorNative.guard(owner,owns&&mouseFree):-9 catch(_:Dynamic){guardStatus=-1;}
        try policyStatus=hasPolicy?CursorNative.policy(owner,true,mouseFree,owns):-9 catch(_:Dynamic){policyStatus=-1;}
        try {if(hasConfinement&&active)CursorNative.confinement(!free);}catch(_:Dynamic){}
        try pointerStatus=hasPointer?CursorNative.pointer(owner,owns&&connected&&hidePointer):-9 catch(_:Dynamic){pointerStatus=-1;}
        if(helperReady)
            supportIssue=guardStatus<0||policyStatus<0||pointerStatus<0||navigation.status<0?"SFCursor could not activate. Restart Farever after extracting the full ControllerRemap ZIP.":"";
    }
    public function cancel():Void state.cancel();
}
