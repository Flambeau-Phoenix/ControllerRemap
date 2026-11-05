package controllerremap;

/** One-shot focus handoffs across independently scrolling ImGui children. */
class EditorFocus {
    public static inline var FILTERS=0;
    public static inline var ACTIONS=1;
    public static inline var EDITOR=2;
    public static inline var PROFILES=3;
    public static inline var CONTROLLER=4;
    public static inline var WINDOW=5;
    public static inline var OPTIONS=6;
    static var order=[WINDOW,FILTERS,OPTIONS,ACTIONS,EDITOR,PROFILES,CONTROLLER];
    public var current(default,null)=ACTIONS;
    public var pending(default,null)=-1;
    public function new(){}
    public function request(section:Int):Void {if(section>=0&&section<=OPTIONS){current=section;pending=section;}}
    public function move(direction:Int,hasAction:Bool,hasRows:Bool=true):Void {
        if(direction==0)return;
        var index=order.indexOf(current),step=direction<0?-1:1;
        index=(index+step+order.length)%order.length;
        while(order[index]==EDITOR&&!hasAction||order[index]==ACTIONS&&!hasRows)index=(index+step+order.length)%order.length;
        request(order[index]);
    }
    public function consume(section:Int):Bool {if(pending!=section)return false;pending=-1;return true;}
    public function mark(section:Int):Void {if(pending<0)current=section;}
    public function reset():Void {current=ACTIONS;pending=-1;}
}
