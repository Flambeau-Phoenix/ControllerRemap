import controllerremap.OverrideSession;
class OverrideSessionTest {
    static var checks=0;
    static function check(ok:Bool,why:String){checks++;if(!ok)throw why;}
    static function main(){
        var base={value:1},custom={value:2},foreign={value:3};
        var table:Map<String,Dynamic>=["Jump"=>base];var fail=false;
        var s=new OverrideSession<Dynamic>(function(id)return table.get(id),function(id,v){if(fail)throw "refused";table.set(id,v);});
        s.write("Jump",custom);check(table.get("Jump")==custom&&s.count==1,"override active");
        s.restore();check(table.get("Jump")==base&&s.count==0,"toggle off restores original identity");
        s.restore();check(table.get("Jump")==base,"repeated off harmless");
        s.write("Jump",custom);table.set("Jump",foreign);s.restore();
        check(table.get("Jump")==foreign&&s.count==0,"foreign replacement preserved");
        s.write("Jump",custom);fail=true;var threw=false;try s.restore()catch(_:Dynamic)threw=true;
        check(threw&&s.count==1,"failed restore retains ownership");fail=false;s.restore();
        check(table.get("Jump")==foreign&&s.count==0,"failed restore can be retried");
        Sys.println("PASS "+checks+" override ownership checks");
    }
}
