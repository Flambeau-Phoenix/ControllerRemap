import controllerremap.ActionLabels;
import controllerremap.ActionGroups;
class ActionLabelsTest {
    static function main():Void {
        var cases=[{id:"WeaponSkill1",text:"Weapon Skill 1"},{id:"Menu_TabNext",text:"Menu Tab Next"},{id:"UILeft",text:"UI Left"},{id:"Jump",text:"Jump"},{id:"AimSkillConfirm",text:"Confirm skill aim"},{id:"WeaponMode",text:"Weapon mode hold"}];
        for(c in cases)if(ActionLabels.display(c.id)!=c.text)throw "Wrong caption: "+c.id;
        if(!ActionGroups.matches(2,"WeaponSkill1","X","X","weapon skill","Weapon Skill 1"))throw "Friendly caption search failed";
        Sys.println("PASS 7 action caption/search checks");
    }
}
