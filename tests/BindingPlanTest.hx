import controllerremap.BindingPlan;
import controllerremap.Profile.ProfilePad;
class BindingPlanTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function p(button:String,mod=-1,mode=-1):ProfilePad return {pad:button,mod:mod,mode:mode};
    static function main():Void {
        var layout:Map<String,Array<ProfilePad>>=["Jump"=>[p("A")],"Attack"=>[p("X"),p("Y")],"Menu_LeftClick"=>[p("A")],"WeaponMode"=>[p("RT")],"ClassMode"=>[p("LT")],"WeaponSkill1"=>[p("DpadUp",-1,0)],"Skill1"=>[p("DpadUp",-1,1)]];
        var plan=new BindingPlan("Jump",[p("X")],layout);
        check(plan.conflicts.length==1&&plan.conflicts[0].action=="Attack","find existing gameplay owner");
        check(plan.move.get("Attack").length==1&&plan.move.get("Attack")[0].pad=="Y","move preserves nonconflicting alternatives");
        check(plan.swap!=null&&plan.swap.get("Attack")[0].pad=="A","swap gives old binding to previous owner");
        check(layout.get("Jump")[0].pad=="A"&&layout.get("Attack")[0].pad=="X","planning is read-only");
        check(!plan.move.exists("Menu_LeftClick"),"gameplay move preserves menu bindings");
        plan=new BindingPlan("Jump",[p("A")],layout);check(plan.conflicts.length==0,"unchanged assignment is not a new conflict");
        plan=new BindingPlan("Jump",[],layout);check(plan.conflicts.length==0&&plan.move.get("Jump").length==0,"unbinding does not steal buttons");
        plan=new BindingPlan("Attack",[p("A")],layout);check(plan.conflicts.length==1&&plan.move.get("Jump").length==0,"last conflicting alternative becomes None");
        plan=new BindingPlan("Jump",[p("DpadUp")],layout);check(plan.conflicts.length==0,"direct assignment preserves weapon and class mode bindings");
        check(!plan.move.exists("WeaponSkill1")&&!plan.move.exists("Skill1"),"mode owners are excluded from a direct move");
        plan=new BindingPlan("Jump",[p("DpadUp",5)],layout);check(plan.conflicts.length==0,"explicit RT hold and weapon mode are distinct bindings");
        plan=new BindingPlan("WeaponSkill1",[p("DpadUp",-1,0)],layout);check(plan.conflicts.length==0,"native weapon/class sharing is retained");
        plan=new BindingPlan("Jump",[p("DpadUp",4)],layout);check(plan.conflicts.length==0,"independent LB chord does not erase LT/RT chords");
        layout.set("Dash",[p("A")]);
        plan=new BindingPlan("Jump",[p("X")],layout);check(plan.swap==null&&plan.swapReason.indexOf("Dash")>=0,"reject ambiguous displaced binding");
        plan=new BindingPlan("Jump",[p("X"),p("B")],layout);check(plan.swap==null,"adding alternatives does not invent a previous swap binding");
        var uses=BindingPlan.uses("RT",layout);
        check(uses.length==2,"lookup includes selector and gated skill");
        check([for(use in uses)if(use.action=="WeaponSkill1"&&use.asMode)use].length==1,"lookup explains native mode use");
        layout.set("WeaponMode",[p("RB")]);
        check([for(use in BindingPlan.uses("RB",layout))if(use.action=="WeaponSkill1"&&use.asMode)use].length==1,"lookup follows remapped mode selector");
        check([for(use in BindingPlan.uses("RT",layout))if(use.action=="WeaponSkill1")use].length==0,"lookup drops previous selector");
        layout.set("Interact",[p("B",4)]);
        check([for(use in BindingPlan.uses("LB",layout))if(use.action=="Interact"&&use.asHold)use].length==1,"lookup includes explicit hold modifier");
        check(BindingPlan.uses("Start",layout).length==0,"empty lookup is well-defined");
        layout.set("OpenInventory",[p("Y")]);
        check(new BindingPlan("Jump",[p("Y")],layout).conflicts.length==2,"window-opening shortcuts overlap gameplay input");
        layout.set("Pad_X",[p("X")]);
        check(new BindingPlan("Jump",[p("X")],layout).conflicts.length==1,"raw pad aliases are retained");
        layout.set("Jump",[p("X")]);
        check(new BindingPlan("Jump",[p("X")],layout,true).conflicts.length==1,"explicit reassignment discovers an existing shared button");
        for(mod in [-1,3,4,5,6])for(mode in [-1,0,1]){
            var a=p("DpadRight",mod,mode);
            check(BindingPlan.overlaps(a,a,layout),"same chord overlaps");
            check(!BindingPlan.overlaps(a,p("DpadLeft",mod,mode),layout),"different primary button does not overlap");
            for(otherMod in [-1,3,4,5,6])for(otherMode in [-1,0,1])
                check(BindingPlan.overlaps(a,p("DpadRight",otherMod,otherMode),layout)==(mod==otherMod&&mode==otherMode),"only the complete identical chord conflicts");
        }
        var scoped:Map<String,Array<ProfilePad>>=["Jump"=>[p("X")],"Attack"=>[p("A"),p("A",3)],"Interact"=>[p("A",3)],"Menu_LeftClick"=>[p("A"),p("A",3)],"WeaponSkill1"=>[p("A",-1,0)],"Skill1"=>[p("A",-1,1)]];
        plan=new BindingPlan("Jump",[p("A")],scoped);
        check(plan.conflicts.length==1&&plan.conflicts[0].action=="Attack","combat A only conflicts with combat A");
        check(plan.move.get("Attack").length==1&&plan.move.get("Attack")[0].mod==3,"moving combat A preserves combat LT+A");
        check(!plan.move.exists("Menu_LeftClick")&&!plan.move.exists("Interact")&&!plan.move.exists("Skill1")&&!plan.move.exists("WeaponSkill1"),"move leaves other contexts and hold sets untouched");
        plan=new BindingPlan("Jump",[p("A",3)],scoped);
        check(plan.conflicts.length==2&&plan.move.get("Attack").length==1&&plan.move.get("Attack")[0].mod<0,"moving LT+A preserves plain A");
        check(!plan.move.exists("Menu_LeftClick"),"menu LT+A is independent of combat LT+A");
        scoped.set("Dash",[p("X",3)]);
        plan=new BindingPlan("Jump",[p("A")],scoped);
        check(plan.swap!=null,"a held use of the displaced button does not block an exact swap");
        Sys.println("PASS "+checks+" binding plan and button lookup checks");
    }
}
