package controllerremap.ui;

import imgui.ImGui;

/** SolarFlare's typed payload pattern, specialized to retained controller button IDs. */
class DragDropHelper {
    static inline var PAYLOAD="CONTROLLERREMAP_BUTTON";
    static var bytes:Array<haxe.io.Bytes>=[];
    public static function init(buttons:Array<String>):Void {bytes=[for(button in buttons)haxe.io.Bytes.ofString(button+"\x00")];}
    public static function buttonSource(index:Int,label:String):Void {
        if(!ImGui.beginDragDropSource(0))return;
        var failure:Dynamic=null;
        try {var data=bytes[index];ImGui.setDragDropPayload(PAYLOAD,data.getData(),data.length);ImGui.textUnformatted(label);}catch(e:Dynamic)failure=e;
        ImGui.endDragDropSource();if(failure!=null)throw failure;
    }
    public static function buttonTarget():String {
        if(!ImGui.beginDragDropTarget())return null;
        var result:String=null;var failure:Dynamic=null;
        try {
            var payload=ImGui.acceptDragDropPayload(PAYLOAD);
            if(payload!=null&&ImGui.ImGuiPayload_IsDataType(payload,PAYLOAD)){
                var size=ImGui.getPayloadDataSize(payload),raw=ImGui.getPayloadData(payload);
                if(raw!=null&&size>1&&size<=32){
                    if(raw.getUI8(size-1)!=0)throw "Invalid controller payload";
                    var content=raw.toBytes(size);
                    var candidate=content.getString(0,size-1);
                    if(controllerremap.Remap.PADS.indexOf(candidate)>=0)result=candidate;
                }
            }
        }catch(e:Dynamic)failure=e;
        ImGui.endDragDropTarget();if(failure!=null)throw failure;return result;
    }
}
