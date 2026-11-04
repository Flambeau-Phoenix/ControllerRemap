package controllerremap;

/** Cursor transitions and explicit F10 commands have separate lifetimes.
 * Camera lock disables editing; it must not cancel a manual open in that same frame.
 */
class WindowInput {
    var previousLocked:Null<Bool>=null;
    var nextToggle:Float=-1;
    public function new(){}
    public function update(open:Bool,locked:Null<Bool>,hotkey:Bool,now:Float):Bool {
        if(locked!=null){
            if(previousLocked==false&&locked==true)open=false;
            previousLocked=locked;
        }
        if(hotkey&&now>=nextToggle){open=!open;nextToggle=now+0.25;}
        return open;
    }
}
