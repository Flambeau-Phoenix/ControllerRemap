package imgui.ref;
class BoolRef {
    var value:Bool;
    public function new(value:Bool)this.value=value;
    public function get():Bool return value;
    public function set(value:Bool):Void this.value=value;
}
