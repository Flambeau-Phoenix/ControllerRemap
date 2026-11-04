package controllerremap;

/** Editor-only grouping. Action IDs and runtime binding behavior stay unchanged. */
class ActionGroups {
    public static var labels(default,null):Array<String>=["All actions","Movement","Attacks","Menus","Items","Camera","Other"];
    public static var descriptions(default,null):Array<String>=[
        "All controller actions, including advanced bindings.",
        "Movement, jumping, dodging, mounting and respawning.",
        "Attacks, skills, targeting, aim confirmation and weapon/class modes.",
        "Menus, dialogs, maps, windows and interface shortcuts.",
        "Consumables and interaction with the world.",
        "Camera, cinematics and spectator controls.",
        "Raw controller inputs, trailer/editor shortcuts and uncategorized actions."
    ];
    public static function of(id:String):Int {
        if(id==null)return 6;
        switch(id){
            case "Jump","Dash","Mount","Respawn","MoveForward","MoveBack","MoveLeft","MoveRight","Sprint","Walk","Crouch","Dodge","Roll":return 1;
            case "Attack","Secondary","LockTarget","ClassMode","WeaponMode","ContextualSkill","SignatureSkill":return 2;
            case "Interact","Loot","PickUp","UseItem":return 4;
            case "CloseWindow","DialogConfirm","SeeDetails","LeftClick","RightClick","MiddleClick","CtrlLeftClick","CtrlRightClick","ShiftLeftClick","ShiftRightClick","UILeft","UIRight","UseFloatingCursor":return 3;
            case "Skip_Cinematic":return 5;
            default:
        }
        if(StringTools.startsWith(id,"WeaponSkill")||StringTools.startsWith(id,"Skill")||StringTools.startsWith(id,"GroupSkill")||StringTools.startsWith(id,"AimSkill"))return 2;
        if(StringTools.startsWith(id,"Consumable")||StringTools.startsWith(id,"Item_"))return 4;
        if(StringTools.startsWith(id,"Menu_")||StringTools.startsWith(id,"Map_")||StringTools.startsWith(id,"Open"))return 3;
        if(StringTools.startsWith(id,"Cin")||StringTools.startsWith(id,"Camera")||StringTools.startsWith(id,"Spectate"))return 5;
        return 6;
    }
    public static function matches(group:Int,id:String,current:String,planned:String,query:String,label:String=""):Bool {
        if(group>0&&group<labels.length&&of(id)!=group)return false;
        return query==""||id.toLowerCase().indexOf(query)>=0||label.toLowerCase().indexOf(query)>=0||current.toLowerCase().indexOf(query)>=0||planned.toLowerCase().indexOf(query)>=0;
    }
}
