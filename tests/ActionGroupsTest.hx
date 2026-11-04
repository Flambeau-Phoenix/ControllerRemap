import controllerremap.ActionGroups;
class ActionGroupsTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function main():Void {
        var examples=[
            {group:1,ids:["Jump","Dash","Mount","Respawn"]},
            {group:2,ids:["Attack","Secondary","WeaponSkill1","Skill4","GroupSkill1","AimSkillCancel","ClassMode","WeaponMode","LockTarget"]},
            {group:3,ids:["Menu_Back","Menu_LeftClick","Map_ZoomIn","OpenChat","OpenMapWindow","CloseWindow","DialogConfirm","UILeft","CtrlRightClick"]},
            {group:4,ids:["Interact","Consumable1","Consumable4","UseItem"]},
            {group:5,ids:["CinMoveSpeedIncrease","SpectateNext","Skip_Cinematic","CameraZoom"]},
            {group:6,ids:["Pad_X","ShortcutTrailer1","Editor_MoveFaster","FutureUnrecognizedAction"]}
        ];
        for(example in examples)for(id in example.ids){
            check(ActionGroups.of(id)==example.group,"incorrect group: "+id);
            check(ActionGroups.matches(0,id,"RT + A","RB + X",""),"All actions must retain every binding");
            var visible=0;for(g in 1...ActionGroups.labels.length)if(ActionGroups.matches(g,id,"","",""))visible++;
            check(visible==1,"each action must appear in exactly one group");
        }
        check(ActionGroups.matches(1,"Jump","A","RT + DpadUp","dpadup"),"search finds planned binding in the selected group");
        check(!ActionGroups.matches(2,"Jump","A","RT + DpadUp","dpadup"),"search respects the selected group");
        check(ActionGroups.matches(0,"Jump","A","B","jump"),"All actions search finds action ID");
        Sys.println("PASS "+checks+" action grouping checks");
    }
}
