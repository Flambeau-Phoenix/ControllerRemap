package imgui;
import imgui.Structs.ImVec2;
import imgui.ref.BoolRef;
class ImGui {
    public static var shown=true;
    public static var begins=0;
    public static var ends=0;
    public static var styles=0;
    public static var popupEnds=0;
    public static var focuses=0;
    public static function setNextWindowFocus():Void focuses++;
    public static function vec2(x:Float,y:Float):ImVec2 return {x:x,y:y};
    public static function setNextWindowSize(size:ImVec2,cond:Int):Void {}
    public static function setNextWindowSizeConstraints(a:ImVec2,b:ImVec2):Void {}
    public static function setNextWindowBgAlpha(alpha:Float):Void {}
    public static function getMainViewport():Dynamic return null;
    public static function ImGuiViewport_GetCenter(vp:Dynamic):ImVec2 return {x:500,y:400};
    public static function setNextWindowPos(pos:ImVec2,cond:Int):Void {}
    public static function pushStyleVar(kind:Int,value:ImVec2):Void styles++;
    public static function popStyleVar():Void styles--;
    public static function begin(title:String,open:BoolRef,flags:Int):Bool {begins++;return shown;}
    public static function end():Void ends++;
    public static function isItemClicked(button:Int):Bool return false;
    public static function openPopup(id:String):Void {}
    public static function beginPopup(id:String):Bool return shown;
    public static function endPopup():Void popupEnds++;
    public static function menuItem(label:String,shortcut:String,selected:Bool,enabled:Bool):Bool return false;
}
