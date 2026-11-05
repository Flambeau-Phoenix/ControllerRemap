package controllerremap;

/** Own only the pad-focus change we make; drain held presses before handing control back. */
class InputFocusLease {
    public var owned(default,null)=false;
    var previous=false;
    var read:Void->Bool;
    var write:Bool->Void;
    public function new(read:Void->Bool,write:Bool->Void){this.read=read;this.write=write;}
    public function update(wanted:Bool,focused:Bool,held:Bool):Void {
        if(!focused)return;
        if(wanted||(owned&&held)){
            if(!owned){previous=read();owned=true;}
            write(false);
        }else if(owned){
            if(!read())write(previous);
            owned=false;
        }
    }
}
