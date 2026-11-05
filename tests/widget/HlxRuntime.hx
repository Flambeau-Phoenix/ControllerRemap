import hlx.runtime.ResolvedMember;
/** UI fixture: resolves no game memory and rejects any attempted game interaction. */
class HlxRuntime {
    public static function resolveType(name:String):hl.Bytes return @:privateAccess name.toUtf8();
    public static function resolveMember(type:hl.Bytes,name:String):ResolvedMember throw "UI fixture attempted engine resolution";
    public static function resolveStaticMember(type:hl.Bytes,name:String):ResolvedMember throw "UI fixture attempted engine resolution";
    public static function callResolved(member:ResolvedMember,args:Array<Dynamic>):Dynamic throw "UI fixture attempted engine call";
    public static function resolveField(obj:Dynamic,name:String):Dynamic return Reflect.field(obj,name);
    public static function setField(obj:Dynamic,name:String,value:Dynamic):Void Reflect.setField(obj,name,value);
    public static function resolveStaticField(type:hl.Bytes,name:String):Dynamic throw "UI fixture attempted engine static read";
    public static function setStaticField(type:hl.Bytes,name:String,value:Dynamic):Void throw "UI fixture attempted engine static write";
    public static function constructEnum(type:hl.Bytes,name:String,args:Array<Dynamic>):Dynamic throw "UI fixture attempted engine allocation";
    public static function constructInstance(type:hl.Bytes,index:Int,args:Array<Dynamic>):Dynamic throw "UI fixture attempted engine allocation";
    public static function constructInstanceByName(type:hl.Bytes,count:Int,args:Array<Dynamic>):Dynamic throw "UI fixture attempted engine allocation";
    public static function allocInstance(type:hl.Bytes):Dynamic throw "UI fixture attempted engine allocation";
    public static function resolveAbstract<T>(value:Dynamic,sample:T):T return cast value;
    public static function unboxPointer(value:Dynamic):hl.Bytes throw "UI fixture attempted engine pointer access";
    public static function moduleName():String return "controller-widget-test";
    public static function registerPrefix(key:Dynamic,fn:Dynamic,receiver:Dynamic):Void throw "UI fixture attempted hook registration";
    public static function registerPostfix(key:Dynamic,fn:Dynamic,receiver:Dynamic):Void throw "UI fixture attempted hook registration";
    public static function dispatch(key:Dynamic,args:Array<Dynamic>):Dynamic throw "UI fixture attempted hook dispatch";
}
