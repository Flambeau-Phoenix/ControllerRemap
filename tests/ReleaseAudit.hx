import format.hl.Data.HLType;
class ReleaseAudit {
    static function main():Void {
        var path=Sys.args()[0],input=sys.io.File.read(path,true);
        var data:format.hl.Data.Data;
        try data=new format.hl.Reader(false).read(input)catch(e:Dynamic){input.close();throw e;}
        input.close();
        var libraries=new Map<String,Bool>();
        for(n in data.natives){
            libraries.set(n.lib,true);
            if(n.lib.toLowerCase().indexOf("sfpad")>=0)throw "Release imports the removed logging helper";
        }
        for(t in data.types)switch(t){case HObj(p):if(p.name=="controllerremap.PadHelper")throw "Release retains the controller logger";default:}
        for(s in data.strings)if(s=="controller_helper_log.txt")throw "Release retains the controller recording path";
        sys.io.File.saveContent("build/release-imports.json",haxe.Json.stringify([for(n in data.natives)if(n.lib=="sfimgui"){library:n.lib,name:n.name}],null,"  "));
        Sys.println("PASS release bytecode audit: no sfpad imports, logger type or controller recording path");
    }
}
