import controllerremap.Profile;
class ProfileTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function body(actions:Dynamic,swap:Dynamic=false):String return haxe.Json.stringify({format:"controllerremap.profile.v1",swapConfirmCancel:swap,actions:actions});
    static function decode(json:String) return Profile.decode(json,["Jump","Attack"],["A","B","RT","DpadUp"]);
    static function reject(json:String):Void {var failed=false;try decode(json)catch(_:Dynamic)failed=true;check(failed,"invalid profile accepted: "+json);}
    static function main():Void {
        var one={pad:"A",modifier:-1,mode:-1};
        var d=decode(body([{action:"Jump",entries:[]},{action:"Attack",entries:[one]}],true));
        check(d.actions.exists("Jump")&&d.actions.get("Jump").length==0,"cleared pad bindings survive JSON load");
        check(d.actions.get("Attack")[0].pad=="A"&&d.swap,"button and A/B switch survive load");
        d=decode(body([{action:"FutureAction",entries:[one]}]));check(d.skipped==1,"unknown actions counted");
        for(mod in [-1,3,4,5,6])for(mode in [-1,0,1]){
            d=decode(body([{action:"Jump",entries:[{pad:"DpadUp",modifier:mod,mode:mode}]}]));
            check(d.actions.get("Jump")[0].mod==mod&&d.actions.get("Jump")[0].mode==mode,"trigger combo survives load");
        }
        reject("null");reject("[]");reject("{}");reject(body({}));reject(body("bad"));reject(body([],1));
        reject(body([null]));reject(body([{action:3,entries:[]}]));reject(body([{action:"Jump",entries:{}}]));
        reject(body([{action:"Jump",entries:[null]}]));
        reject(body([{action:"Jump",entries:[{pad:"Alien",modifier:-1,mode:-1}]}]));
        reject(body([{action:"Jump",entries:[{pad:"A",modifier:2,mode:-1}]}]));
        reject(body([{action:"Jump",entries:[{pad:"A",modifier:-1,mode:8}]}]));
        reject(body([{action:"Jump",entries:[{pad:"A",modifier:"3",mode:-1}]}]));
        reject(body([{action:"Jump",entries:[]},{action:"Jump",entries:[]}]));
        reject(body([{action:"Jump",entries:[one,one,one,one,one]}]));
        for(name in ["Narnun","Emuru RT arrows","A-B_2","CONsole"])check(Profile.validName(name),"valid filename");
        for(name in ["","CON","nul","COM1","LPT9","../x","x/y","a.json","a:"," ending "])check(!Profile.validName(name),"invalid filename");
        Sys.println("PASS "+checks+" profile checks");
    }
}
