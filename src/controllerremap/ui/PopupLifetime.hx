package controllerremap.ui;

import imgui.ImGui;

/** Close only popups submitted by this remapper, inside their owning scope. */
class PopupLifetime {
    public static var closing=false;
    public static function dismiss():Bool {
        if(!closing)return false;
        ImGui.closeCurrentPopup();return true;
    }
}
