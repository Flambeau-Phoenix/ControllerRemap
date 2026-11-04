import controllerremap.ui.UiCol;
class UiColorTest {
    static var checks=0;
    static function check(ok:Bool,why:String):Void {checks++;if(!ok)throw why;}
    static function main():Void {
        check(UiCol.rgb(0xff0000)==0xff0000ff,"red remains red in ImGui ABGR packing");
        check(UiCol.rgb(0x0000ff)==0xffff0000,"blue has the opposite packed byte order");
        check(UiCol.fromArgb(0xffff0000)==UiCol.rgb(0xff0000),"ARGB conversion preserves intended warning red");
        check(UiCol.rgba(1,2,3,4)==0x04030201,"channel order is ABGR");
        check(UiCol.withAlpha(UiCol.rgb(0xff0000),128)==0x800000ff,"alpha replacement preserves red channel");
        check(UiCol.lighten(UiCol.rgb(0x800000),0)==UiCol.rgb(0x800000),"zero lighten preserves warning color");
        check(UiCol.darken(UiCol.rgb(0xff0000),0)==UiCol.rgb(0xff0000),"zero darken preserves warning color");
        check((UiCol.darken(UiCol.rgb(0xff0000),0.5)&255)==127,"darkening affects intended red channel");
        Sys.println("PASS "+checks+" UI color channel checks");
    }
}
