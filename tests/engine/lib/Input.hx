package lib;
import controllerremap.NativeBindings.NativeBind;
/** Offline model of the observed bytecode: defaults copied; user slot zero replaces slot zero. */
class Input {
    public static var defaultBinds=new hlx.std.haxe.ds.StringMap();
    public static var userBinds=new hlx.std.haxe.ds.StringMap();
    public static var bindingsPerMode=new hlx.std.haxe.ds.IntMap();
    public static var refuseAction="";
    public static function getBindings(id:String):hl.types.ArrayBase {
        var raw:Array<NativeBind>=cast defaultBinds.get(id);
        var a=raw==null?[]:raw.copy();
        var u:Array<NativeBind>=cast userBinds.get(id);
        if(u!=null&&u.length>0)a[0]=u[0];
        if(id==refuseAction)a=[];
        return cast a;
    }
}
