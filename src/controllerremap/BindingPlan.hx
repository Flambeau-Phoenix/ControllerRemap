package controllerremap;

import controllerremap.Profile.ProfilePad;

typedef BindingConflict = {action:String,index:Int,binding:ProfilePad};
typedef ButtonUse = {action:String,bindings:Array<ProfilePad>,asButton:Bool,asHold:Bool,asMode:Bool};

/** Pure, previewable edits. All layouts here include the scoped A/B switch. */
class BindingPlan {
    public var action(default,null):String;
    public var before(default,null):Array<ProfilePad>;
    public var after(default,null):Array<ProfilePad>;
    public var conflicts(default,null):Array<BindingConflict>=[];
    public var move(default,null):Map<String,Array<ProfilePad>>=new Map();
    public var swap(default,null):Map<String,Array<ProfilePad>>=null;
    public var swapReason(default,null)="Swap needs one changed binding and one conflicting action.";

    public static function copy(pads:Array<ProfilePad>):Array<ProfilePad> return [for(p in pads){pad:p.pad,mod:p.mod,mode:p.mode}];
    public static function equal(a:ProfilePad,b:ProfilePad):Bool return a.pad==b.pad&&a.mod==b.mod&&a.mode==b.mode;
    static function contains(pads:Array<ProfilePad>,p:ProfilePad):Bool {for(other in pads)if(equal(p,other))return true;return false;}
    public static function modifier(code:Int):String return switch(code){case 3:"LT";case 4:"LB";case 5:"RT";case 6:"RB";default:"";};

    public static function context(id:String):String return InputFamilies.family(id);
    /** Only an identical button, explicit hold and mode hold can conflict.
     * Context is checked by the planner; A, LT+A and class-mode A stay separate.
     */
    public static function overlaps(a:ProfilePad,b:ProfilePad,layout:Map<String,Array<ProfilePad>>):Bool {
        return equal(a,b);
    }

    public function new(id:String,wanted:Array<ProfilePad>,layout:Map<String,Array<ProfilePad>>,rescan:Bool=false) {
        action=id;before=copy(layout.get(id));after=copy(wanted);
        var added=[for(p in after)if(rescan||!contains(before,p))p];
        var others=[for(key in layout.keys())if(key!=id&&InputFamilies.conflicts(key,id))key];others.sort(Reflect.compare);
        for(key in others){
            var pads=layout.get(key);
            for(i in 0...pads.length)for(p in added)if(overlaps(p,pads[i],layout)){
                conflicts.push({action:key,index:i,binding:pads[i]});break;
            }
        }
        move.set(action,copy(after));
        for(key in others){
            var drop=[for(c in conflicts)if(c.action==key)c.index];
            if(drop.length>0){var pads=layout.get(key);move.set(key,[for(i in 0...pads.length)if(drop.indexOf(i)<0){pad:pads[i].pad,mod:pads[i].mod,mode:pads[i].mode}]);}
        }
        buildSwap(layout);
    }
    function buildSwap(layout:Map<String,Array<ProfilePad>>):Void {
        if(conflicts.length!=1||before.length!=after.length)return;
        var changed=-1;
        for(i in 0...before.length)if(!equal(before[i],after[i])){if(changed>=0)return;changed=i;}
        if(changed<0)return;
        var hit=conflicts[0],other=copy(layout.get(hit.action));
        other[hit.index]={pad:before[changed].pad,mod:before[changed].mod,mode:before[changed].mode};
        // A swapped-out button must not introduce a second unresolved collision.
        for(key in layout.keys()){
            if(key==hit.action||!InputFamilies.conflicts(key,hit.action))continue;
            var pads=key==action?after:layout.get(key);
            for(p in pads)if(overlaps(p,other[hit.index],layout)){
                swapReason="The previous binding is also used by "+ActionLabels.display(key)+". Confirm move or cancel instead.";return;
            }
        }
        swap=new Map();swap.set(action,copy(after));swap.set(hit.action,other);swapReason="";
    }

    /** Every use of a physical button, including modifier and mode-selector use. */
    public static function uses(button:String,layout:Map<String,Array<ProfilePad>>):Array<ButtonUse> {
        var result:Array<ButtonUse>=[],keys=[for(key in layout.keys())key];keys.sort(Reflect.compare);
        for(key in keys){
            var matched:Array<ProfilePad>=[],primary=false,hold=false,mode=false;
            for(p in layout.get(key)){
                var isButton=p.pad==button,isHold=modifier(p.mod)==button,isMode=false;
                if(p.mode>=0){
                    var selectors=layout.get(p.mode==0?"WeaponMode":"ClassMode");
                    if(selectors!=null)for(selector in selectors)if(selector.pad==button||modifier(selector.mod)==button)isMode=true;
                }
                if(isButton||isHold||isMode){matched.push({pad:p.pad,mod:p.mod,mode:p.mode});primary=primary||isButton;hold=hold||isHold;mode=mode||isMode;}
            }
            if(matched.length>0)result.push({action:key,bindings:matched,asButton:primary,asHold:hold,asMode:mode});
        }
        return result;
    }
}
