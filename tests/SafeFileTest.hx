import controllerremap.SafeFile;
import sys.FileSystem;
import sys.io.File;
class SafeFileTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function strictRename(a:String,b:String):Void {
        if(FileSystem.exists(b))throw "Host rename refuses an existing destination";
        FileSystem.rename(a,b);
    }
    static function main():Void {
        var dir="build/save-test-"+Std.random(1000000000);
        FileSystem.createDirectory(dir);var path=dir+"/profile.json";
        SafeFile.write(path,"first",strictRename);check(File.getContent(path)=="first","first save");
        File.saveContent(path+".tmp","second");var refused=false;
        try strictRename(path+".tmp",path)catch(_:Dynamic)refused=true;
        check(refused&&File.getContent(path)=="first","reproduces game's non-overwriting rename behavior");
        SafeFile.write(path,"second",strictRename);
        check(File.getContent(path)=="second","overwrite succeeds with non-overwriting host rename");
        check(!FileSystem.exists(path+".tmp")&&!FileSystem.exists(path+".previous"),"verified commit clears temporary and previous files");
        for(i in 0...20)SafeFile.write(path,"layout-"+i,strictRename);
        check(File.getContent(path)=="layout-19","repeated profile/settings updates persist");
        var failed=false;
        try SafeFile.write(path,"pending",function(a,b){if(a==path+".tmp")throw "commit refused";strictRename(a,b);})catch(_:Dynamic)failed=true;
        check(failed&&File.getContent(path)=="layout-19","failed replacement restores last saved file");
        check(File.getContent(path+".tmp")=="pending","failed save preserves recoverable pending data");
        SafeFile.write(path,"recovered",strictRename);check(File.getContent(path)=="recovered","save recovers after a prior failure");
        Sys.println("PASS "+checks+" profile replacement checks with strict Windows rename semantics");
    }
}
