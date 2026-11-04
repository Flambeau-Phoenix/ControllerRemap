package controllerremap.ui;
class UiChrome {
    public static var depth=0;
    public static function pushCelShade():Int {depth++;return 1;}
    public static function popCelShade(count:Int):Void depth-=count;
}
