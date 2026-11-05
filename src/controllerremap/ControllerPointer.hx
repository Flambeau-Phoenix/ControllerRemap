package controllerremap;

/** Controller opens without a pointer; explicit mouse use hands it back. */
class ControllerPointer {
    public var hidden(default,null)=false;
    public function new(){}
    public function update(open:Bool,connected:Bool,focused:Bool,opening:Bool,controllerUsed:Bool,mouseUsed:Bool):Void {
        if(!open||!connected){hidden=false;return;}
        if(!focused)return;
        if(opening||controllerUsed)hidden=true;
        if(mouseUsed)hidden=false;
    }
}
