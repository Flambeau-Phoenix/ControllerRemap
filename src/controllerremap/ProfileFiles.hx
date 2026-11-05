package controllerremap;

import sys.FileSystem;
import sys.io.File;

/** Profile file operations validate before mutation and never overwrite another profile on rename/import. */
class ProfileFiles {
    public static function freeName(base:String,names:Array<String>):String {
        var name=base,n=2;
        while(true){
            var found=false;for(other in names)if(other.toLowerCase()==name.toLowerCase()){found=true;break;}
            if(!found)return name;
            if(n>1000)throw "Too many profiles with that name";
            var suffix=" "+n++;name=base.substr(0,40-suffix.length)+suffix;
        }
    }
    static function path(dir:String,name:String):String {
        if(!Profile.validName(name))throw "Invalid profile name";
        return dir+"/"+name+".json";
    }
    static function encode(data:Dynamic):String {
        var json=haxe.Json.stringify(data,null,"  ");
        if(haxe.io.Bytes.ofString(json).length>Profile.MAX_BYTES)throw "Profile is too large";
        return json;
    }
    public static function exists(dir:String,name:String,except:String=""):Bool {
        for(file in FileSystem.readDirectory(dir))if(file.toLowerCase()==(name+".json").toLowerCase()&&file!=except+".json")return true;
        return false;
    }
    public static function read(dir:String,name:String,ids:Array<String>,buttons:Array<String>):String {
        var source=path(dir,name);
        if(FileSystem.isDirectory(source)||FileSystem.stat(source).size>Profile.MAX_BYTES)throw "Invalid profile file";
        var json=File.getContent(source);Profile.decode(json,ids,buttons);return json;
    }
    public static function rename(dir:String,from:String,to:String,ids:Array<String>,buttons:Array<String>):Void {
        var source=path(dir,from),target=path(dir,to);
        var json=read(dir,from,ids,buttons);
        if(from==to)return;
        if(exists(dir,to,from))throw "That profile name already exists";
        var data:Dynamic=haxe.Json.parse(json);data.name=to;
        var content=encode(data);
        var staging=source+".renaming";
        if(FileSystem.exists(staging))throw "A previous rename needs recovery";
        FileSystem.rename(source,staging);
        try {
            SafeFile.write(target,content);
        }catch(e:Dynamic){
            if(!FileSystem.exists(source))FileSystem.rename(staging,source);
            throw e;
        }
        // A retained source backup is safer than treating successful rename as a failed operation.
        try FileSystem.deleteFile(staging)catch(_:Dynamic){}
    }
    /** Import only creates a saved profile. Loading it remains an explicit action. */
    public static function importJson(dir:String,json:String,ids:Array<String>,buttons:Array<String>):String {
        if(json==null||haxe.io.Bytes.ofString(json).length>Profile.MAX_BYTES)throw "Profile is too large";
        Profile.decode(json,ids,buttons);
        var data:Dynamic=haxe.Json.parse(json);
        var raw:Dynamic=Reflect.field(data,"name");
        var base=Std.isOfType(raw,String)&&Profile.validName(raw)?Std.string(raw):"Imported layout";
        var names=[for(file in FileSystem.readDirectory(dir))if(StringTools.endsWith(file.toLowerCase(),".json"))file.substr(0,file.length-5)];
        var name=freeName(base,names);
        data.name=name;SafeFile.write(path(dir,name),encode(data));
        return name;
    }
}
