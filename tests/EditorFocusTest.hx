import controllerremap.EditorFocus;
import controllerremap.ControllerLegend;
class EditorFocusTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function main():Void {
        var f=new EditorFocus(),visited=new Map<Int,Bool>();
        for(_ in 0...7){visited.set(f.current,true);f.move(1,true);}
        check(f.current==EditorFocus.ACTIONS,"forward section cycle returns to list");
        for(section in [EditorFocus.WINDOW,EditorFocus.FILTERS,EditorFocus.OPTIONS,EditorFocus.ACTIONS,EditorFocus.EDITOR,EditorFocus.PROFILES,EditorFocus.CONTROLLER]){
            check(visited.exists(section),"every panel region is in the cycle: "+section);
            check(ControllerLegend.text(section,false,false,false)!="","every region has a visible legend");
        }
        for(_ in 0...7)f.move(-1,true);check(f.current==EditorFocus.ACTIONS,"reverse section cycle returns to list");
        f.reset();for(_ in 0...6){f.move(1,false);check(f.current!=EditorFocus.EDITOR,"empty editor is skipped");}
        check(f.current==EditorFocus.ACTIONS,"cycle remains complete without an action selection");
        f.request(EditorFocus.FILTERS);f.move(1,false,false);check(f.current==EditorFocus.OPTIONS,"empty list keeps options reachable");
        f.move(1,false,false);check(f.current==EditorFocus.PROFILES,"empty list and editor are skipped on forward cycle");
        f.move(-1,false,false);check(f.current==EditorFocus.OPTIONS,"empty list and editor are skipped on reverse cycle");
        f.request(EditorFocus.FILTERS);check(f.consume(EditorFocus.FILTERS)&&!f.consume(EditorFocus.FILTERS),"focus requests are one-shot");
        check(ControllerLegend.text(0,true,false,false).indexOf("B is bindable")>=0,"listening legend does not present B as cancel");
        check(ControllerLegend.text(0,false,true,false).indexOf("B: cancel")>=0,"conflict legend presents cancel");
        check(ControllerLegend.text(0,false,false,true).indexOf("Dropdown")>=0,"dropdown legend follows popup state");
        Sys.println("PASS "+checks+" cyclic focus and legend checks");
    }
}
