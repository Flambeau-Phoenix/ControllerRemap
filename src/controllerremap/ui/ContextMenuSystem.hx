package controllerremap.ui;

import imgui.ImGui;

/** SolarFlare's item-bound context menus, exported without game-icon dependencies. */
class ContextMenuSystem {
    public static function openForItem(id:String,mouseButton:Int=1):Bool {
        if(!ImGui.isItemClicked(mouseButton))return false;
        ImGui.openPopup(id);return true;
    }
    public static function draw(id:String,body:Void->Void):Void {
        if(!ImGui.beginPopup(id))return;
        var failure:Dynamic=null;try {if(!PopupLifetime.dismiss())body();}catch(e:Dynamic)failure=e;
        ImGui.endPopup();if(failure!=null)throw failure;
    }
    public static function menuItem(label:String,enabled:Bool=true,selected:Bool=false):Bool return ImGui.menuItem(label,"",selected,enabled);
}
