import controllerremap.WindowInput;
class WindowInputTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function main():Void {
        var p=new WindowInput();var open=false;
        open=p.update(open,true,true,1);check(open,"F10 opens while camera locked; same frame must not close it");
        open=p.update(open,true,false,1.1);check(open,"staying in camera mode must not undo manual open");
        open=p.update(open,true,true,1.12);check(open,"duplicate ImGui/game signal must not toggle twice");
        open=p.update(open,true,true,1.4);check(!open,"F10 closes in camera mode");
        open=p.update(open,false,true,2);check(open,"F10 opens in free cursor mode");
        open=p.update(open,true,false,2.1);check(!open,"entering camera mode closes an interactive editor");
        open=p.update(open,false,false,2.2);check(!open,"free cursor does not reopen closed editor");
        open=p.update(open,false,true,2.5);check(open,"editor can reopen after camera transition");
        open=p.update(false,false,false,2.6);check(!open,"close button remains closed");
        open=p.update(open,null,true,3);check(open,"F10 opens while cursor state is unavailable");
        open=p.update(open,null,false,3.1);check(open,"unknown cursor state does not close panel");
        p=new WindowInput();open=p.update(false,false,false,4);
        open=p.update(open,true,true,4.5);check(open,"explicit F10 open takes precedence over concurrent camera transition");
        p=new WindowInput();check(p.update(false,false,true,5),"ImGui-only F10 signal opens");
        p=new WindowInput();check(p.update(false,true,true,5),"game-key-only F10 signal opens");
        Sys.println("PASS "+checks+" F10 and camera transition checks");
    }
}
