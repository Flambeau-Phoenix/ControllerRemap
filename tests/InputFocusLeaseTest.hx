import controllerremap.InputFocusLease;
class InputFocusLeaseTest {
    static var checks=0;
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function main():Void {
        var focus=true,writes=0;
        var lease=new InputFocusLease(function()return focus,function(value){focus=value;writes++;});
        lease.update(false,true,false);check(focus&&writes==0,"idle UI never changes game focus");
        lease.update(true,true,false);check(!focus&&lease.owned,"UI acquires its pad-focus lease");
        lease.update(false,true,true);check(!focus&&lease.owned,"held close press cannot fire in the game");
        lease.update(false,true,false);check(focus&&!lease.owned,"neutral release restores original game focus");
        focus=false;lease.update(true,true,false);lease.update(false,true,false);
        check(!focus&&!lease.owned,"originally unfocused pad stays unfocused");
        focus=true;lease.update(true,true,false);var before=writes;
        lease.update(false,false,false);check(!focus&&writes==before&&lease.owned,"focus loss never forces background input on");
        lease.update(false,true,false);check(focus&&!lease.owned,"returning to foreground completes the pending handoff");
        lease.update(true,true,false);focus=true;before=writes;lease.update(false,true,false);
        check(focus&&writes==before&&!lease.owned,"another layer's changed focus is not overwritten");
        Sys.println("PASS "+checks+" controller focus ownership checks");
    }
}
