package controllerremap;

/** Reversible ownership of native table entries. Foreign replacements are never overwritten. */
class OverrideSession<T> {
    var original:Map<String,T>=new Map();
    var written:Map<String,T>=new Map();
    var get:String->T;
    var set:(String,T)->Void;
    public var count(get,never):Int;
    function get_count():Int {var n=0;for(_ in written.keys())n++;return n;}
    public function new(get:String->T,set:(String,T)->Void){this.get=get;this.set=set;}
    public function write(id:String,value:T):Void {
        if(!original.exists(id))original.set(id,get(id));
        written.set(id,value); // Own even a setter that mutates and then throws.
        set(id,value);
        if(get(id)!=value)throw "Native table refused "+id;
    }
    public function restore():Void {
        var errors:Array<String>=[];
        for(id in [for(k in written.keys())k]){
            try {
                if(get(id)==written.get(id)){
                    set(id,original.get(id));
                    if(get(id)!=original.get(id))throw "restore refused";
                }
                original.remove(id);written.remove(id);
            }catch(_:Dynamic){errors.push(id);}
        }
        if(errors.length>0)throw "Could not restore: "+errors.join(", ");
    }
}
