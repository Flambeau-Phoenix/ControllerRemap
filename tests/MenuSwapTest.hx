import controllerremap.Remap;
import controllerremap.NativeBindings.NativeBind;
import lib.Input;

/** Exercise the production swap/override code with both menu directions, not only Cancel. */
class MenuSwapTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function bind(button:String,key:Null<Int>=null):NativeBind return {code:key,modifier:null,mode:null,padCode:button==null?null:HlxRuntime.resolveStaticField("gamepad.PadInputCode",button)};
    static function main():Void {
        var click:Array<NativeBind>=[bind(null,1),bind("A")],back:Array<NativeBind>=[bind("B")];
        var close:Array<NativeBind>=[bind(null,27),bind("B")],aim:Array<NativeBind>=[bind(null,1),bind("A")];
        Input.defaultBinds.set("Menu_LeftClick",click);Input.defaultBinds.set("Menu_Back",back);
        Input.defaultBinds.set("CloseWindow",close);Input.defaultBinds.set("AimSkillConfirm",aim);
        Input.defaultBinds.set("Menu_Confirm",[bind("Start")]);
        Input.defaultBinds.set("DialogConfirm",[bind("A")]);Input.defaultBinds.set("AimSkillCancel",[bind("B")]);
        Input.defaultBinds.set("Attack",[bind("A")]);Input.defaultBinds.set("Jump",[bind("B")]);
        Remap.start(1);check(Remap.ready,"menu binding inventory is ready");
        var keyboard=Remap.keyboardSignature("Menu_LeftClick")+Remap.keyboardSignature("CloseWindow");
        Remap.setSwap(true);check(!Remap.applyFailed&&Remap.appliedCount==4,"checkbox applies all four scoped actions together");
        check(Remap.readPads("Menu_LeftClick")[0].pad=="B","confirm/click changes A to B");
        check(Remap.readPads("Menu_Back")[0].pad=="A","cancel/back changes B to A");
        check(Remap.readPads("CloseWindow")[0].pad=="A"&&Remap.readPads("AimSkillConfirm")[0].pad=="B","window close and aim confirm swap too");
        Input.heldButtons=["A"];
        check(!Input.isDownPad("Menu_LeftClick")&&Input.isDownPad("Menu_Back"),"after swap A cancels and does not click in the offline input evaluator");
        Input.heldButtons=["B"];
        check(Input.isDownPad("Menu_LeftClick")&&!Input.isDownPad("Menu_Back"),"after swap B clicks and does not cancel in the offline input evaluator");
        check(Remap.readPads("Menu_Confirm")[0].pad=="Start","separate Menu Confirm remains Start, matching the screenshot");
        check(Remap.readPads("Attack")[0].pad=="A"&&Remap.readPads("Jump")[0].pad=="B","checkbox does not swap gameplay actions");
        check(Remap.readPads("DialogConfirm")[0].pad=="A"&&Remap.readPads("AimSkillCancel")[0].pad=="B","document the exact limited scope; dialog confirm and aim cancel are separate");
        check(keyboard==Remap.keyboardSignature("Menu_LeftClick")+Remap.keyboardSignature("CloseWindow"),"mouse and keyboard bindings are unchanged");
        for(_ in 0...5)Remap.apply();
        check(Remap.readPads("Menu_LeftClick")[0].pad=="B"&&Remap.readPads("Menu_Back")[0].pad=="A","repeated Apply cannot swap one side back");
        check(Remap.saveProfile("Menu swap"),"save checkbox-only profile");
        Remap.clearAll();Remap.loadProfile("Menu swap");
        check(Remap.swapAB&&Remap.readPads("Menu_LeftClick")[0].pad=="B"&&Remap.readPads("Menu_Back")[0].pad=="A","checkbox-only profile restores both directions");
        Remap.setEnabled(false);
        check(Input.defaultBinds.get("Menu_LeftClick")==click&&Input.defaultBinds.get("Menu_Back")==back,"overrides off restores the exact original menu arrays");
        Remap.setEnabled(true);
        check(Remap.readPads("Menu_LeftClick")[0].pad=="B"&&Remap.readPads("Menu_Back")[0].pad=="A","overrides on reapplies both directions");
        Remap.setSwap(false);
        check(Input.defaultBinds.get("Menu_LeftClick")==click&&Input.defaultBinds.get("Menu_Back")==back,"unchecking restores both originals");
        Input.refuseAction="Menu_LeftClick";Remap.setSwap(true);
        check(Remap.applyFailed&&Remap.appliedCount==0,"failed confirm read-back rejects the whole operation");
        check(Input.defaultBinds.get("Menu_Back")==back&&Input.defaultBinds.get("CloseWindow")==close&&Input.defaultBinds.get("AimSkillConfirm")==aim,"failed confirm cannot leave only Cancel swapped");
        Input.refuseAction="";Remap.apply();
        check(!Remap.applyFailed&&Remap.readPads("Menu_LeftClick")[0].pad=="B"&&Remap.readPads("Menu_Back")[0].pad=="A","retry recovers both directions");
        Sys.println("PASS "+checks+" A/B menu swap checks (production code, offline engine fixture)");
    }
}
