package controllerremap;

typedef ProfilePad = {pad:String, mod:Int, mode:Int};
typedef DecodedProfile = {actions:Map<String,Array<ProfilePad>>, swap:Bool, skipped:Int};

/** Pure profile validation. Reflection here only touches parsed JSON, never engine objects. */
class Profile {
    public static inline var MAX_BYTES=262144;
    public static function validName(name:String):Bool {
        if(name==null||name.length==0||name.length>40||StringTools.trim(name)!=name) return false;
        if(!~/^[A-Za-z0-9 _-]+$/.match(name)) return false;
        var upper=name.toUpperCase();
        return !~/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/.match(upper);
    }
    public static function decode(json:String,ids:Array<String>,buttons:Array<String>):DecodedProfile {
        if(json==null||json.length>MAX_BYTES) throw "profile is too large";
        var d:Dynamic=haxe.Json.parse(json);
        if(d==null||Reflect.field(d,"format")!="controllerremap.profile.v1") throw "not a ControllerRemap profile";
        var raw:Dynamic=Reflect.field(d,"actions");
        if(!Std.isOfType(raw,Array)) throw "actions must be an array";
        var list:Array<Dynamic>=cast raw;
        if(list.length>512) throw "too many actions";
        var swap:Dynamic=Reflect.field(d,"swapConfirmCancel");
        if(!Std.isOfType(swap,Bool)) throw "swapConfirmCancel must be true or false";
        var next=new Map<String,Array<ProfilePad>>(), seen=new Map<String,Bool>();var skipped=0;
        for(a in list){
            if(a==null) throw "missing action";
            var id:Dynamic=Reflect.field(a,"action"), es:Dynamic=Reflect.field(a,"entries");
            if(!Std.isOfType(id,String)||!Std.isOfType(es,Array)) throw "invalid action or entries";
            var key:String=id, entries:Array<Dynamic>=cast es;
            if(seen.exists(key)) throw "duplicate action: "+key;
            seen.set(key,true);
            if(entries.length>4) throw "too many bindings for "+key;
            var pads:Array<ProfilePad>=[];
            for(e in entries){
                if(e==null) throw "missing binding for "+key;
                var p:Dynamic=Reflect.field(e,"pad"), m:Dynamic=Reflect.field(e,"modifier"), mode:Dynamic=Reflect.field(e,"mode");
                if(!Std.isOfType(p,String)||buttons.indexOf(p)<0||!Std.isOfType(m,Int)||!Std.isOfType(mode,Int)) throw "invalid binding for "+key;
                if([-1,3,4,5,6].indexOf(m)<0||[-1,0,1].indexOf(mode)<0) throw "invalid hold for "+key;
                pads.push({pad:p,mod:m,mode:mode});
            }
            if(ids.indexOf(key)<0){skipped++;continue;}
            next.set(key,pads); // Empty arrays deliberately clear an action's pad bindings.
        }
        return {actions:next,swap:swap,skipped:skipped};
    }
}
