import controllerremap.ProfileFiles;
import controllerremap.Profile;
import sys.FileSystem;
import sys.io.File;
class ProfileFilesTest {
    static var checks=0;
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function fails(fn:Void->Void,label:String):Void {var failed=false;try fn()catch(_:Dynamic)failed=true;check(failed,label);}
    static function main():Void {
        var dir="build/profile-files-"+Std.random(1000000000);FileSystem.createDirectory(dir);
        var ids=["Jump"],buttons=["A","B"];
        check(ProfileFiles.freeName("Layout",["layout","LAYOUT 2"])=="Layout 3","new profile names avoid case-insensitive collisions");
        var data={format:"controllerremap.profile.v1",name:"Original",swapConfirmCancel:true,actions:[{action:"Jump",entries:[{pad:"B",modifier:-1,mode:-1}]}],future:{value:42}};
        var json=haxe.Json.stringify(data);File.saveContent(dir+"/Original.json",json);
        ProfileFiles.rename(dir,"Original","Renamed",ids,buttons);
        check(!FileSystem.exists(dir+"/Original.json")&&FileSystem.exists(dir+"/Renamed.json"),"rename changes filename");
        var renamed:Dynamic=haxe.Json.parse(ProfileFiles.read(dir,"Renamed",ids,buttons));
        check(renamed.name=="Renamed"&&renamed.future.value==42,"rename updates name while retaining other metadata");
        var decoded=Profile.decode(haxe.Json.stringify(renamed),ids,buttons);
        check(decoded.swap&&decoded.actions.get("Jump")[0].pad=="B","rename preserves all assignments and A/B switch");
        File.saveContent(dir+"/Other.json",json);
        fails(function()ProfileFiles.rename(dir,"Renamed","other",ids,buttons),"case-insensitive collision is rejected");
        check(File.getContent(dir+"/Other.json")==json&&FileSystem.exists(dir+"/Renamed.json"),"collision preserves both profiles");
        fails(function()ProfileFiles.rename(dir,"Renamed","../outside",ids,buttons),"rename cannot escape profile folder");
        fails(function()ProfileFiles.rename(dir,"Renamed","CON",ids,buttons),"rename rejects Windows reserved names");
        ProfileFiles.rename(dir,"Renamed","RENAMED",ids,buttons);
        check(haxe.Json.parse(File.getContent(dir+"/RENAMED.json")).name=="RENAMED","case-only rename works");
        var first=ProfileFiles.importJson(dir,json,ids,buttons),second=ProfileFiles.importJson(dir,json,ids,buttons);
        check(first=="Original"&&second=="Original 2","import chooses a free name without overwriting");
        check(File.getContent(dir+"/Other.json")==json,"import leaves existing files unchanged");
        check(Profile.decode(ProfileFiles.read(dir,second,ids,buttons),ids,buttons).swap,"import/export format round trip");
        var before=FileSystem.readDirectory(dir).length;
        fails(function()ProfileFiles.importJson(dir,"{}",ids,buttons),"invalid clipboard JSON rejected");
        check(FileSystem.readDirectory(dir).length==before,"invalid import creates no file");
        data.name="../unsafe";check(ProfileFiles.importJson(dir,haxe.Json.stringify(data),ids,buttons)=="Imported layout","unsafe imported filename becomes a safe label");
        File.saveContent(dir+"/Broken.json","{}");
        fails(function()ProfileFiles.rename(dir,"Broken","Should not exist",ids,buttons),"invalid saved data cannot be renamed into a valid-looking file");
        check(FileSystem.exists(dir+"/Broken.json")&&!FileSystem.exists(dir+"/Should not exist.json"),"failed validation preserves original");
        var near:Dynamic=haxe.Json.parse(json);near.padding="";
        var padding=haxe.io.Bytes.alloc(Profile.MAX_BYTES-haxe.Json.stringify(near).length);padding.fill(0,padding.length,120);near.padding=padding.toString();
        fails(function()ProfileFiles.importJson(dir,haxe.Json.stringify(near),ids,buttons),"expanded output cannot create a profile larger than the reader accepts");
        Sys.println("PASS "+checks+" rename and profile sharing checks");
    }
}
