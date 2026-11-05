package controllerremap;

import imgui.ImGui;
import controllerremap.ui.ContextMenuSystem;
import controllerremap.ui.PopupLifetime;

/** Local port of the shared context-menu pattern, with callback-owned cleanup. */
class UiMenus {
    public static function openForItem(id:String):Bool {
        return ContextMenuSystem.openForItem(id);
    }
    public static function popup(id:String,body:Void->Void):Void {
        ContextMenuSystem.draw(id,body);
    }
    public static function bar(body:Void->Void):Void {
        if(!ImGui.beginMenuBar())return;
        var failure:Dynamic=null;try body()catch(e:Dynamic)failure=e;
        ImGui.endMenuBar();if(failure!=null)throw failure;
    }
    public static function menu(label:String,body:Void->Void,enabled:Bool=true):Void {
        if(!ImGui.beginMenu(label,enabled))return;
        var failure:Dynamic=null;try {if(!PopupLifetime.dismiss())body();}catch(e:Dynamic)failure=e;
        ImGui.endMenu();if(failure!=null)throw failure;
    }
    public static function item(label:String,enabled:Bool=true,selected:Bool=false):Bool return ContextMenuSystem.menuItem(label,enabled,selected);
}
