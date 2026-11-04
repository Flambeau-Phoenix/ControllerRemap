package hlx.std.haxe.ds;
class IntMap {
    var map:Map<Int,Dynamic>=new Map();
    public function new(){}
    public function get(k:Int):Dynamic return map.get(k);
    public function set(k:Int,v:Dynamic):Void map.set(k,v);
    public function clear():Void map.clear();
    public function iterator():Iterator<Dynamic> return map.iterator();
    public function copy():IntMap {var out=new IntMap();for(k in map.keys())out.set(k,map.get(k));return out;}
}
