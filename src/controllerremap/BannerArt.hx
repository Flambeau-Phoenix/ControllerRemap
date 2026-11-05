package controllerremap;

import imgui.ImGui;
import imgui.Structs.ImVec2;

/** Embedded PNG decoded/uploaded once during observation; draw only scales its cached texture. */
class BannerArt {
    public var texture(default,null):hl.I64=0;
    public var width(default,null)=1300;
    public var height(default,null)=372;
    public var size(default,null):ImVec2;
    var uv0:ImVec2;var uv1:ImVec2;
    var attempted=false;
    public function new(){size=ImGui.vec2(300,300*372/1300);uv0=ImGui.vec2(0,0);uv1=ImGui.vec2(1,1);}
    public function observe():Void {
        if(attempted)return;attempted=true;
        try {
            var raw=haxe.Resource.getBytes("controllerremap-banner");if(raw==null)return;
            var png=new format.png.Reader(new haxe.io.BytesInput(raw)).read(),header=format.png.Tools.getHeader(png);
            if(header.width<=0||header.height<=0||header.width>2048||header.height>1024)return;
            width=header.width;height=header.height;
            var bgra=format.png.Tools.extract32(png),rgba=haxe.io.Bytes.alloc(bgra.length);
            for(i in 0...Std.int(bgra.length/4)){var p=i*4;rgba.set(p,bgra.get(p+2));rgba.set(p+1,bgra.get(p+1));rgba.set(p+2,bgra.get(p));rgba.set(p+3,bgra.get(p+3));}
            texture=ImGui.registerTexture(rgba.getData(),width,height,width*4);
        }catch(_:Dynamic){}
    }
    public function draw(available:Float):Void {
        size.x=Math.max(1,Math.min(300,available));size.y=size.x*height/width;
        if(texture!=(0:hl.I64))ImGui.image(texture,size,uv0,uv1);
        else {controllerremap.ui.UiChrome.heading("Controller Remap",1.6);}
    }
}
