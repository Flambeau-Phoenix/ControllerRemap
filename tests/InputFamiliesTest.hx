import controllerremap.InputFamilies;
import controllerremap.BindingPlan;
import controllerremap.Profile.ProfilePad;
class InputFamiliesTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function p(button:String,mod=-1,mode=-1):ProfilePad return {pad:button,mod:mod,mode:mode};
    static function main():Void {
        check(InputFamilies.same("Attack","Jump"),"combat and jump share gameplay context");
        check(!InputFamilies.same("Jump","Respawn")&&InputFamilies.protectedSharing("Respawn"),"death input honors native NoConflict");
        check(InputFamilies.same("Respawn","SpectateNext"),"death actions remain available for explicit within-family swaps");
        check(!InputFamilies.same("Attack","Menu_LeftClick")&&!InputFamilies.same("Menu_LeftClick","Map_ZoomIn"),"gameplay, menu and map families remain separate");
        check(InputFamilies.same("Attack","OpenInventory"),"catalogue UIs grouping does not hide gameplay window-opening collisions");
        check(!InputFamilies.same("FutureAction","Attack")&&!InputFamilies.same("FutureAction","FutureAction2"),"unknown actions are independently scoped");
        check(!InputFamilies.same("Menu_FutureAction","Menu_Back")&&!InputFamilies.same("AimSkillFutureAction","AimSkillConfirm"),"unknown prefixes cannot inherit a known consumer family");
        InputFamilies.record("FutureAction",0,0);check(!InputFamilies.same("FutureAction","Attack"),"an unknown catalogue member is not guessed to be gameplay");
        var layout:Map<String,Array<ProfilePad>>=["Attack"=>[p("X")],"Jump"=>[p("A"),p("B")],"Respawn"=>[p("A")],"Menu_LeftClick"=>[p("A")],"Map_ZoomIn"=>[p("A")],"AimSkillConfirm"=>[p("A")],"Pad_X"=>[p("A")]];
        var plan=new BindingPlan("Attack",[p("A")],layout);
        check(plan.conflicts.length==1&&plan.conflicts[0].action=="Jump","A Attack conflicts with Jump alone");
        check(plan.move.get("Jump").length==1&&plan.move.get("Jump")[0].pad=="B","move only clears the conflicting gameplay alternative");
        for(id in ["Respawn","Menu_LeftClick","Map_ZoomIn","AimSkillConfirm","Pad_X"])check(!plan.move.exists(id)&&!plan.swap.exists(id),"move and swap preserve other family: "+id);
        check(plan.swap.get("Jump")[0].pad=="X"&&plan.swap.get("Jump")[1].pad=="B","swap exchanges the displaced gameplay slot only");
        check(layout.get("Respawn")[0].pad=="A"&&layout.get("Jump")[0].pad=="A","planning does not mutate originals");
        layout.set("SpectateNext",[p("Y")]);
        check(new BindingPlan("Respawn",[p("Y")],layout).conflicts.length==0,"native shared input is not automatically stolen even within death family");
        layout.set("SeeDetails",[p("A")]);
        check(new BindingPlan("Menu_LeftClick",[p("A")],layout,true).conflicts.length==0,"NoConflict menu details sharing remains intact");
        var held=new BindingPlan("Attack",[p("A",3)],layout);
        check(held.conflicts.length==0,"independent hold slots remain separate");
        InputFamilies.record("Jump",1,0);
        check(new BindingPlan("Attack",[p("A")],layout).conflicts.length==0,"live native NoConflict policy supersedes the snapshot");
        InputFamilies.record("Jump",0,0);
        check(new BindingPlan("Attack",[p("A")],layout).conflicts.length==1,"clearing live NoConflict restores ordinary family collision checks");
        Sys.println("PASS "+checks+" input family planning checks");
    }
}
