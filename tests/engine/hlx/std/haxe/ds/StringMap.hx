package hlx.std.haxe.ds;
class StringMap {
    var map:Map<String,Dynamic>=new Map();
    public function new(){}
    public function get(k:String):Dynamic return map.get(k);
    public function set(k:String,v:Dynamic):Void map.set(k,v);
    public function exists(k:String):Bool return map.exists(k);
    public function keys():Iterator<String> return map.keys();
}
