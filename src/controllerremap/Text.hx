package controllerremap;

/** Retained UTF-8, NUL-terminated native ImGui input buffer. Create it from main(), never as a static initializer. */
class Text {
    public var bytes(default,null):hl.Bytes;
    public var size(default,null):Int;
    public function new(size:Int,value:String="") {this.size=size;bytes=new hl.Bytes(size);set(value);}
    public function set(value:String):Void {
        var b=haxe.io.Bytes.ofString(value==null?"":value);
        var n=Std.int(Math.min(size-1,b.length));
        if(n<b.length) while(n>0 && (b.get(n)&0xC0)==0x80) n--;
        bytes.fill(0,size,0);bytes.blit(0,b.getData(),0,n);
    }
    public function get():String return @:privateAccess String.fromUTF8(bytes);
}
