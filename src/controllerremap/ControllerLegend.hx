package controllerremap;

/** Persistent, contextual hints; strings are retained rather than built during draw. */
class ControllerLegend {
    public static var common(default,null)="RS: scroll focused area | X/Y: section | Alt: mouse | F10 / LT+RT+RB+A: close";
    static var ordinary=[
        "Categories | D-pad: buttons | A: actions | LB/RB (L1/R1): category | B: actions",
        "Keymap list | A / Right: edit | Up at top / Left / B: categories | LB/RB: category",
        "Bindings | D-pad: move | A: choose / Listen | B: actions | LB/RB: section",
        "Profiles | D-pad: move | A: choose | B: actions | LB/RB: section",
        "Controller diagram | D-pad: move | A: inspect | B: actions | LB/RB: section",
        "Window actions | A: choose | Down / B: categories | LB/RB: section",
        "Options/search | D-pad: move | A: choose | B: categories | LB/RB: section"
    ];
    public static function text(section:Int,listening:Bool,conflict:Bool,popup:Bool):String {
        if(listening)return "Listening | Release buttons, then press one to bind | B is bindable | Esc: cancel";
        if(conflict)return "Binding conflict | D-pad: choose | A: selected option | B: cancel | RS: scroll changes";
        if(popup)return "Dropdown/menu | Up/Down: choose | A: select | B: back | RS: scroll";
        return ordinary[section>=0&&section<ordinary.length?section:EditorFocus.ACTIONS];
    }
    public static function footer(listening:Bool,popup:Bool):String return listening?"Esc: cancel listening | F10: close":(popup?"F10 / LT+RT+RB+A: close | Alt: mouse":common);
}
