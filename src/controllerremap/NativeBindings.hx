package controllerremap;

import controllerremap.Remap.Pad;

typedef NativeBind={code:Null<Int>,modifier:Null<Int>,mode:Null<Int>,padCode:Dynamic};

/** Observe-only bridge. Pad bindings live in defaults; userBinds overrides slot zero only.
 * Keep native keyboard entries and the user's map intact. Restore original arrays by identity.
 */
class NativeBindings {
    /** Observe-only metadata. The pure planner never reads live engine records. */
    public static function observeFamilies(ids:Array<String>):Void {
        try {
            var input=HlxRuntime.resolveStaticField(HlxRuntime.resolveType("Data"),"input");
            if(input==null)return;
            var raw=HlxRuntime.resolveField(input,"byId");if(raw==null)return;
            var table:hlx.std.haxe.ds.StringMap=cast raw;
            for(id in ids){
                var row=table.get(id);if(row==null)continue;
                var f:Dynamic=HlxRuntime.resolveField(row,"flags"),g:Dynamic=HlxRuntime.resolveField(row,"group");
                if(Std.isOfType(f,Int)&&Std.isOfType(g,Int))InputFamilies.record(id,f,g);
            }
        }catch(_:Dynamic){}
    }
    var defaults:hlx.std.haxe.ds.StringMap;
    var session:OverrideSession<Dynamic>;
    var oldModes:hlx.std.haxe.ds.IntMap;
    var ownModes:hlx.std.haxe.ds.IntMap;
    var enumValues:Map<String,Dynamic>=new Map();
    public var count(get,never):Int;
    function get_count():Int return session==null?0:session.count;
    public function new(){
        defaults=lib.Input.defaultBinds;
        session=new OverrideSession(function(id)return defaults.get(id),function(id,value)defaults.set(id,value));
    }
    public function current():Bool return defaults==lib.Input.defaultBinds&&(ownModes==null||lib.Input.bindingsPerMode==ownModes);
    function value(name:String):Dynamic {
        if(!enumValues.exists(name)){
            var v=HlxRuntime.resolveStaticField(HlxRuntime.resolveType("gamepad.PadInputCode"),name);
            if(v==null)throw "Cannot resolve controller button "+name;
            enumValues.set(name,v);
        }
        return enumValues.get(name);
    }
    public function restore():Void {
        session.restore();
        if(ownModes!=null&&lib.Input.bindingsPerMode==ownModes)lib.Input.bindingsPerMode=oldModes;
        ownModes=null;oldModes=null;
    }
    public function apply(actions:Map<String,Array<Pad>>,ids:Array<String>):Void {
        restore();
        var any=false;for(_ in actions.keys()){any=true;break;}
        if(!any)return;
        try {
            for(id in actions.keys()){
                var raw=defaults.get(id);
                if(raw==null)throw "No native defaults for "+id;
                var list=lib.Input.getBindings(id);
                if(list==null)throw "Cannot read native bindings for "+id;
                if(list.length<0||list.length>32)throw "Invalid native binding list";
                var next:Array<NativeBind>=[];
                for(i in 0...list.length){
                    var b:Dynamic=list.getDyn(i);
                    if(b!=null&&HlxRuntime.resolveField(b,"padCode")==null&&HlxRuntime.resolveField(b,"code")!=null)next.push(cast b);
                }
                // The user's keyboard rebind always replaces index 0. Give it a
                // keyboard slot even for formerly pad-only actions.
                if(next.length==0)next.push({code:null,modifier:null,mode:null,padCode:null});
                for(p in actions.get(id))next.push({code:null,modifier:p.mod<0?null:p.mod,mode:p.mode<0?null:p.mode,padCode:value(p.pad)});
                var keyboard=Remap.keyboardSignature(id);
                session.write(id,next);
                var actual=Remap.readPads(id,true);
                if(!Remap.samePads(actual,actions.get(id)))throw "Controller read-back failed for "+id+": "+Remap.text(actual);
                if(Remap.keyboardSignature(id)!=keyboard)throw "Keyboard read-back changed for "+id;
            }
            rebuildModes(ids);
        }catch(e:Dynamic){
            try restore()catch(r:Dynamic)throw Std.string(e)+"; "+Std.string(r);
            throw e;
        }
    }
    function rebuildModes(ids:Array<String>):Void {
        // Mode blocking caches the binding objects, so it must follow replacements.
        var groups:Map<Int,Array<NativeBind>>=new Map();
        for(id in ids){
            var list=lib.Input.getBindings(id);
            if(list==null||list.length<0||list.length>32)throw "Cannot rebuild input modes";
            for(i in 0...list.length){
                var b=list.getDyn(i);if(b==null)continue;
                var mode:Dynamic=HlxRuntime.resolveField(b,"mode");
                if(mode==null)continue;
                if(!Std.isOfType(mode,Int))throw "Invalid native input mode";
                if(!groups.exists(mode))groups.set(mode,[]);
                groups.get(mode).push(cast b);
            }
        }
        var source=lib.Input.bindingsPerMode;
        if(source==null)throw "Native input mode cache is unavailable";
        var cache=source.copy();
        if(cache==null||cache==source)throw "Cannot copy native input mode cache";
        cache.clear();
        for(mode in groups.keys())cache.set(mode,groups.get(mode));
        oldModes=source;ownModes=cache;
        lib.Input.bindingsPerMode=cache;
        if(lib.Input.bindingsPerMode!=cache)throw "Native input mode cache refused replacement";
    }
}
