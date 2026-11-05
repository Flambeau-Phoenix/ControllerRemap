import controllerremap.Remap;
import controllerremap.NativeBindings.NativeBind;
import controllerremap.InputFamilies;
import lib.Input;
class InputFamilyBridgeTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function bind(button:String,key:Null<Int>=null):NativeBind return {code:key,modifier:null,mode:null,padCode:button==null?null:HlxRuntime.resolveStaticField("gamepad.PadInputCode",button)};
    static function p(button:String):controllerremap.Profile.ProfilePad return {pad:button,mod:-1,mode:-1};
    static function main():Void {
        var untouched=new Map<String,Dynamic>();
        for(id in ["Jump","Respawn","Menu_LeftClick","Map_ZoomIn","AimSkillConfirm"]){
            var raw=[bind(null,32),bind("A")];Input.defaultBinds.set(id,raw);if(id!="Jump")untouched.set(id,raw);
        }
        Input.defaultBinds.set("Attack",[bind(null,65),bind("X")]);
        Input.defaultBinds.set("SpectateNext",[bind("RT")]);
        Input.userBinds.set("Attack",[bind(null,90)]);
        var meta=new hlx.std.haxe.ds.StringMap();
        meta.set("Respawn",{flags:1,group:0});meta.set("Jump",{flags:0,group:0});meta.set("Attack",{flags:0,group:0});
        HlxRuntime.dataInput={byId:meta};Remap.start(1);check(Remap.ready,"native-family bridge ready");
        meta.set("Jump",{flags:1,group:0});controllerremap.NativeBindings.observeFamilies(["Jump"]);
        check(InputFamilies.protectedSharing("Jump"),"observe bridge imports native metadata into the cached policy");
        meta.set("Jump",{flags:0,group:0});controllerremap.NativeBindings.observeFamilies(["Jump"]);
        check(!InputFamilies.protectedSharing("Jump"),"observe bridge refreshes changed flags");
        var keyboard=Remap.keyboardSignature("Attack");
        check(!Remap.requestEdit("Attack",[p("A")])&&Remap.pendingEdit.plan.conflicts.length==1&&Remap.pendingEdit.plan.conflicts[0].action=="Jump","production preview scopes collision to Jump");
        check(Remap.resolveEdit(1),"scoped replacement applies");
        check(Remap.readPads("Attack")[0].pad=="A"&&Remap.readPads("Jump").length==0,"gameplay replacement changes only the intended owners");
        for(id in untouched.keys())check(Input.defaultBinds.get(id)==untouched.get(id)&&Remap.readPads(id)[0].pad=="A","other family remains bound with original native array identity: "+id);
        check(Remap.keyboardSignature("Attack")==keyboard,"keyboard mapping survives scoped replacement");
        Remap.clearAll();Remap.requestEdit("Attack",[p("A")]);check(Remap.resolveEdit(2),"production scoped conflict swap applies");
        check(Remap.readPads("Attack")[0].pad=="A"&&Remap.readPads("Jump")[0].pad=="X"&&Remap.readPads("Respawn")[0].pad=="A","swap exchanges Attack and Jump while preserving Respawn A");
        check(!Remap.swapActions("Attack","Respawn")&&Remap.readPads("Respawn")[0].pad=="A","cross-family direct swap is rejected without mutation");
        check(Remap.swapActions("Attack","Jump"),"same-family direct swap works");
        check(Remap.swapActions("Respawn","SpectateNext")&&Remap.readPads("Respawn")[0].pad=="RT"&&Remap.readPads("SpectateNext")[0].pad=="A","explicit death-family swap works despite native shared-input exemption");
        Remap.clearAll();Remap.requestEdit("Attack",[p("A")]);Remap.resolveEdit(2);Remap.saveProfile("Family slots");Remap.clearAll();Remap.loadProfile("Family slots");
        check(Remap.readPads("Attack")[0].pad=="A"&&Remap.readPads("Jump")[0].pad=="X"&&Remap.readPads("Respawn")[0].pad=="A","existing profile format preserves separate action slots across reload");
        Remap.setEnabled(false);check(Remap.readPads("Jump")[0].pad=="A"&&Remap.readPads("Respawn")[0].pad=="A","disabling restores the original shared defaults");
        Remap.setEnabled(true);check(Remap.readPads("Jump")[0].pad=="X"&&Remap.readPads("Respawn")[0].pad=="A","reenabling preserves family boundaries");
        Remap.clearAll();Remap.saveProfile("Rollback baseline");Remap.requestEdit("Attack",[p("A")]);Input.refuseAction="Attack";
        check(!Remap.resolveEdit(1)&&Remap.currentPads("Attack")[0].pad=="X"&&Remap.currentPads("Respawn")[0].pad=="A","failed family edit rolls back both gameplay owners without touching Respawn");
        Input.refuseAction="";Remap.clearAll();
        Sys.println("PASS "+checks+" native family bridge checks");
    }
}
