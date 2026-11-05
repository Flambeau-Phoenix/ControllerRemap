package controllerremap;

/** Only explicit commands close the panel; Alt/cursor visibility never does. */
class WindowInput {
    var nextToggle:Float=-1;
    public function new(){}
    public function update(open:Bool,locked:Null<Bool>,hotkey:Bool,now:Float,controllerMode:Bool=false):Bool {
        if(hotkey&&now>=nextToggle){open=!open;nextToggle=now+0.25;}
        return open;
    }
}
