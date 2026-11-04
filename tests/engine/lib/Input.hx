package lib;
import controllerremap.NativeBindings.NativeBind;
/** Offline model of the observed bytecode: defaults copied; user slot zero replaces slot zero. */
class Input {
    public static var defaultBinds=new hlx.std.haxe.ds.StringMap();
    public static var userBinds=new hlx.std.haxe.ds.StringMap();
    public static var bindingsPerMode=new hlx.std.haxe.ds.IntMap();
    public static var refuseAction="";
    public static var activeModes:Array<Int>=[];
    public static var heldButtons:Array<String>=[];
    /** Model of this build's bindingIsModeBlocked + checkInput pad branch.
     * Mode equality deliberately ignores mode itself, matching the native helper.
     * This is an offline evaluator, not evidence of physical controller success.
     */
    public static function isDownPad(id:String):Bool {
        var list=getBindings(id);
        for(i in 0...list.length){
            var b:NativeBind=cast list.getDyn(i);
            if(b==null||b.padCode==null||modeBlocked(b))continue;
            if(b.modifier!=null){
                var modifier=switch(b.modifier){case 3:"LT";case 4:"LB";case 5:"RT";case 6:"RB";default:"";};
                if(heldButtons.indexOf(modifier)<0)continue;
            }
            if(heldButtons.indexOf(Type.enumConstructor(b.padCode))>=0)return true;
        }
        return false;
    }
    static function modeBlocked(binding:NativeBind):Bool {
        if(binding.mode!=null)return activeModes.indexOf(binding.mode)<0;
        if(activeModes.length==0)return false;
        // The observed implementation scans every mode bucket if a mode is active.
        for(group in bindingsPerMode.iterator()){
            var list:Array<NativeBind>=cast group;
            for(other in list)if(other.code==binding.code&&other.modifier==binding.modifier&&other.padCode==binding.padCode)return true;
        }
        return false;
    }
    public static function getBindings(id:String):hl.types.ArrayBase {
        var raw:Array<NativeBind>=cast defaultBinds.get(id);
        var a=raw==null?[]:raw.copy();
        var u:Array<NativeBind>=cast userBinds.get(id);
        if(u!=null&&u.length>0)a[0]=u[0];
        if(id==refuseAction)a=[];
        return cast a;
    }
}
