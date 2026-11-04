package controllerremap;

import sys.FileSystem;
import sys.io.File;

/** Verified replacement without relying on rename-over-existing support in the host VM. */
class SafeFile {
    public static function write(path:String,content:String,?rename:(String,String)->Void):Void {
        var move=rename==null?FileSystem.rename:rename;
        var temp=path+".tmp";
        File.saveContent(temp,content);
        if(File.getContent(temp)!=content)throw "Temporary file verification failed: "+temp;
        var backup=path+".previous";var n=0;
        while(FileSystem.exists(backup)){
            if(++n>1000)throw "Too many previous save files: "+path;
            backup=path+".previous-"+n;
        }
        var hadOriginal=FileSystem.exists(path);
        if(hadOriginal)move(path,backup);
        try {
            move(temp,path); // Destination is absent even when the host refuses overwrites.
            if(File.getContent(path)!=content)throw "Saved file verification failed: "+path;
        }catch(e:Dynamic){
            try {
                if(FileSystem.exists(path))move(path,backup+".failed");
                if(hadOriginal)move(backup,path);
            }catch(r:Dynamic){throw "Save failed; original preserved at "+backup+": "+Std.string(e)+"; restore: "+Std.string(r);}
            throw e;
        }
        if(hadOriginal)try FileSystem.deleteFile(backup)catch(_:Dynamic){} // A retained backup is harmless.
    }
}
