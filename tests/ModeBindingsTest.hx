import controllerremap.Remap;
import controllerremap.NativeBindings.NativeBind;
import lib.Input;

/** Reproduces inherited mode gating using the bytecode-derived offline input model. */
class ModeBindingsTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function bind(button:String,mode:Null<Int>,key:Null<Int>=null):NativeBind return {
        code:key,modifier:null,mode:mode,padCode:button==null?null:HlxRuntime.resolveStaticField("gamepad.PadInputCode",button)
    };
    static function main():Void {
        var weapon:Array<NativeBind>=[bind(null,null,49),bind("DpadUp",0)];
        var skill:Array<NativeBind>=[bind(null,null,53),bind("DpadUp",1)];
        Input.defaultBinds.set("WeaponSkill1",weapon);Input.defaultBinds.set("Skill1",skill);
        Input.defaultBinds.set("WeaponMode",[bind("RT",null)]);
        Input.defaultBinds.set("ClassMode",[bind("LT",null)]);
        Input.bindingsPerMode.set(0,[weapon[1]]);Input.bindingsPerMode.set(1,[skill[1]]);
        for(i in 2...5){
            var button=["DpadDown","DpadLeft","DpadRight"][i-2];
            var w=bind(button,0),c=bind(button,1);
            Input.defaultBinds.set("WeaponSkill"+i,[bind(null,null,48+i),w]);
            Input.defaultBinds.set("Skill"+i,[bind(null,null,52+i),c]);
            var ws:Array<NativeBind>=cast Input.bindingsPerMode.get(0);ws.push(w);
            var cs:Array<NativeBind>=cast Input.bindingsPerMode.get(1);cs.push(c);
        }
        Remap.start(1);check(Remap.ready,"mode fixture initialized");
        Input.heldButtons=["DpadUp"];Input.activeModes=[];
        check(!Input.isDownPad("WeaponSkill1")&&!Input.isDownPad("Skill1"),"native mode holds reject a direct press");
        Input.activeModes=[0];check(Input.isDownPad("WeaponSkill1")&&!Input.isDownPad("Skill1"),"weapon trigger selects weapon binding");
        Input.activeModes=[1];check(Input.isDownPad("Skill1")&&!Input.isDownPad("WeaponSkill1"),"class trigger selects class binding");

        // Changing only the button preserves the existing mode; this reproduces
        // the reported symptom without any hardcoded skill-dispatch requirement.
        Remap.setOverride("WeaponSkill1",[{pad:"X",mod:-1,mode:0}]);
        Input.heldButtons=["X"];Input.activeModes=[];
        check(!Input.isDownPad("WeaponSkill1"),"changing button alone retains the native trigger requirement");
        check(Remap.removeModeHolds("WeaponSkill1"),"explicit Remove mode hold clears the inherited gate");
        check(Input.isDownPad("WeaponSkill1"),"No hold removes weapon-mode requirement through the production bridge");
        Input.activeModes=[1];check(Input.isDownPad("WeaponSkill1"),"unique direct weapon button also works while class mode is held");
        Remap.setOverride("Skill1",[{pad:"Y",mod:-1,mode:1}]);
        check(Remap.removeModeHolds("Skill1"),"remove the inherited class gate");
        Input.heldButtons=["Y"];Input.activeModes=[];
        check(Input.isDownPad("Skill1"),"No hold removes class-mode requirement");
        Remap.setOverride("WeaponSkill1",[{pad:"DpadRight",mod:4,mode:0}]);
        check(Remap.removeModeHolds("WeaponSkill1")&&Remap.currentPads("WeaponSkill1")[0].mod==4,"removing mode preserves an explicit shoulder hold");
        Input.heldButtons=["DpadRight"];check(!Input.isDownPad("WeaponSkill1"),"explicit LB modifier remains required");
        Input.heldButtons=["LB","DpadRight"];
        check(Input.isDownPad("WeaponSkill1"),"custom LB chord works without RT");
        Remap.saveProfile("Mode Regression");Remap.clearAll();Remap.loadProfile("Mode Regression");
        check(!Remap.applyFailed&&Input.isDownPad("WeaponSkill1"),"direct mode and custom hold persist in profile");
        Input.heldButtons=["Y"];check(Input.isDownPad("Skill1"),"direct class binding persists in profile");
        Remap.setEnabled(false);Input.heldButtons=["DpadUp"];Input.activeModes=[];
        check(!Input.isDownPad("WeaponSkill1")&&!Input.isDownPad("Skill1"),"override off restores native mode requirements");
        Input.activeModes=[0];check(Input.isDownPad("WeaponSkill1"),"original weapon binding remains available after restore");
        Remap.setEnabled(true);
        Remap.setOverride("WeaponSkill1",[{pad:"X",mod:-1,mode:0},{pad:"Y",mod:6,mode:1}]);
        var before=Remap.currentPads("WeaponSkill1");
        check(Remap.modeHint(before)!="","inspector warns about retained mode requirements");
        check(Remap.removeModeHolds("WeaponSkill1"),"clear mode gates across every alternative");
        var direct=Remap.currentPads("WeaponSkill1");
        check(direct.length==2&&direct[0].mode==-1&&direct[1].mode==-1&&direct[1].mod==6,"all alternatives kept with explicit modifiers intact");
        check(before[0].mode==0&&before[1].mode==1,"do not mutate arrays shared with old layouts");
        check(Remap.modeHint(direct)==""&&!Remap.removeModeHolds("WeaponSkill1"),"already-direct bindings do not need another edit");
        check(!Remap.removeModeHolds("Missing")&&!Remap.removeModeHolds(null),"reject invalid action targets");
        Remap.setOverride("WeaponSkill1",[{pad:"X",mod:-1,mode:0}]);Remap.saveProfile("Failure Baseline");
        Input.refuseAction="WeaponSkill1";
        check(!Remap.removeModeHolds("WeaponSkill1"),"reject native refusal when clearing mode");
        check(Remap.currentPads("WeaponSkill1")[0].mode==0&&!Remap.dirty,"restore requested layout and dirty state after refusal");
        Input.refuseAction="";Remap.apply();
        check(!Remap.applyFailed,"old gated layout can be reapplied after refusal");
        Remap.setEnabled(false);var off=Remap.readPads("WeaponSkill1");
        check(Remap.removeModeHolds("WeaponSkill1")&&Remap.samePads(off,Remap.readPads("WeaponSkill1")),"editing disabled override leaves native inputs untouched");
        Remap.setEnabled(true);Input.activeModes=[];Input.heldButtons=["X"];
        check(Input.isDownPad("WeaponSkill1"),"cleared mode applies on re-enable");
        check(Remap.readPads("WeaponMode")[0].pad=="RT"&&Remap.readPads("ClassMode")[0].pad=="LT","mode selectors are not forced on or changed");
        for(prefix in ["WeaponSkill","Skill"])for(i in 1...5){
            var id=prefix+i;Remap.resetOverride(id);
            check(Remap.removeModeHolds(id),"remove inherited mode for "+id);
            Input.activeModes=[];Input.heldButtons=[Remap.currentPads(id)[0].pad];
            check(Input.isDownPad(id),"direct press accepted for "+id);
        }
        Sys.println("PASS "+checks+" mode-binding evaluation checks (offline engine fixture)");
    }
}
