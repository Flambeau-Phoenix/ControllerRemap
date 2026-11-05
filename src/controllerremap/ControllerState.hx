package controllerremap;

/** Pure input lifecycle. Device reads and ImGui forwarding belong to ControllerInput. */
class ControllerState {
    public var listening(default,null)=false;
    public var slot(default,null)=-1;
    public var message(default,null)="";
    public var toggle(default,null)=false;
    public var navigation(default,null)=false;
    public var paneDirection(default,null)=0;
    public var regionDirection(default,null)=0;
    public var back(default,null)=false;
    public var used(default,null)=false;
    public var scrollY(default,null):Float=0;
    var lastSample=0.;
    var neutral=false;
    var deadline=0.;
    var previousChord=false;
    var eligibleBefore=false;
    var previous:Array<Bool>=[for(_ in 0...24)false];

    public function new(){}
    public function begin(index:Int,now:Float):Void {
        slot=index;listening=true;neutral=false;navigation=false;scrollY=0;deadline=now+12;
        message="Release buttons, then press a button.";
    }
    public function cancel(reason:String=""):Void {
        listening=false;slot=-1;neutral=false;navigation=false;scrollY=0;message=reason;
    }
    /** Returns one captured button index. A/B and Start/Back remain assignable. */
    public function update(down:Array<Bool>,connected:Bool,focused:Bool,editing:Bool,now:Float):Int {
        var elapsed=Math.max(0,Math.min(0.05,now-lastSample));lastSample=now;
        toggle=false;navigation=false;paneDirection=0;regionDirection=0;back=false;used=false;scrollY=0;
        var available=connected&&focused;
        var any=false;for(b in down)any=any||b;
        var chord=available&&down[8]&&down[9];
        var shortcutHeld=available&&down[5]&&down[6]&&down[7]; // RB + LT + RT in Farever's mapped layout.
        // Never interpret a held reconnect/focus-return chord as an opening command.
        if(available&&eligibleBefore&&!listening&&((chord&&!previousChord)||(shortcutHeld&&down[0]&&!previous[0]))){
            toggle=true;neutral=false; // Consume the entire opening/closing press until release.
        }
        previousChord=chord;eligibleBefore=available;
        if(!available||!editing){
            if(listening)cancel(!connected?"Controller disconnected.":"Listening cancelled.");
            neutral=false;remember(down);return -1;
        }
        if(listening&&now>=deadline){cancel("Listening timed out.");remember(down);return -1;}
        if(!neutral){
            if(!any){neutral=true;if(listening)message="Press a button. Esc cancels.";}
            remember(down);return -1;
        }
        if(listening){
            var pressed=-1,count=0;
            for(i in 0...down.length)if(down[i]&&!previous[i]){pressed=i;count++;}
            if(count>1){neutral=false;message="Press one button at a time.";}
            else if(count==1){listening=false;neutral=false;message="";remember(down);return pressed;}
        }else {
            navigation=!chord&&!shortcutHeld&&!toggle;
            if(navigation)for(i in 0...24)if(down[i]&&!previous[i])used=true;
            if(navigation&&down[20]!=down[21])scrollY=(down[21]?1:-1)*420*elapsed;
            back=navigation&&down[1]&&!previous[1];
            if(navigation&&down[4]!=down[5]){
                if(down[4]&&!previous[4])paneDirection=-1;
                if(down[5]&&!previous[5])paneDirection=1;
            }
            if(navigation&&down[2]!=down[3]){
                if(down[2]&&!previous[2])regionDirection=1;
                if(down[3]&&!previous[3])regionDirection=-1;
            }
        }
        remember(down);return -1;
    }
    function remember(down:Array<Bool>):Void {for(i in 0...24)previous[i]=down[i];}
}
