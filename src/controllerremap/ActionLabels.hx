package controllerremap;

/** Friendly captions are presentation only; profiles retain the exact engine action IDs. */
class ActionLabels {
    public static function display(id:String):String {
        if(id==null)return "";
        switch(id){
            case "AimSkillConfirm":return "Confirm skill aim";
            case "AimSkillCancel":return "Cancel skill aim";
            case "WeaponMode":return "Weapon mode hold";
            case "ClassMode":return "Class mode hold";
            default:
        }
        var out=new StringBuf();
        for(i in 0...id.length){
            var c=id.charCodeAt(i);
            if(c==95){out.add(" ");continue;}
            var prev=i>0?id.charCodeAt(i-1):0;
            var next=i+1<id.length?id.charCodeAt(i+1):0;
            var upper=c>=65&&c<=90, digit=c>=48&&c<=57;
            var previousLower=prev>=97&&prev<=122, previousUpper=prev>=65&&prev<=90, previousDigit=prev>=48&&prev<=57;
            if(i>0&&prev!=95&&((upper&&(previousLower||previousDigit||(previousUpper&&next>=97&&next<=122)))||(digit&&!previousDigit)))out.add(" ");
            out.addChar(c);
        }
        return out.toString();
    }
}
