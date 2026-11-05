import controllerremap.ControllerPointer;
class ControllerPointerTest {
    static var checks=0;
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function main():Void {
        var p=new ControllerPointer();
        p.update(false,true,true,false,true,false);check(!p.hidden,"closed editor cannot hide pointer");
        p.update(true,true,true,true,false,false);check(p.hidden,"connected controller opens with pointer hidden, including F10");
        p.update(true,true,true,false,false,false);check(p.hidden,"idle keeps controller mode");
        p.update(true,true,true,false,false,true);check(!p.hidden,"Alt exposes pointer for mouse use");
        p.update(true,true,true,false,false,false);check(!p.hidden,"idle does not hide an explicitly exposed pointer");
        p.update(true,true,true,false,true,false);check(p.hidden,"fresh controller input hides pointer again");
        p.update(true,true,true,false,true,true);check(!p.hidden,"explicit mouse intent wins a simultaneous controller press");
        p.update(true,true,true,false,true,false);p.update(true,true,false,false,false,false);check(p.hidden,"focus loss preserves mode without requesting OS cursor changes");
        p.update(true,false,true,false,false,false);check(!p.hidden,"disconnect releases controller mode");
        p.update(true,true,true,false,false,false);check(!p.hidden,"reconnect waits for controller use");
        p.update(true,true,true,false,true,false);check(p.hidden,"fresh reconnect input resumes controller mode");
        p.update(false,true,true,false,false,false);check(!p.hidden,"close releases pointer mode");
        p.update(true,false,true,true,false,false);check(!p.hidden,"mouse-only editor keeps pointer");
        Sys.println("PASS "+checks+" controller pointer mode checks");
    }
}
