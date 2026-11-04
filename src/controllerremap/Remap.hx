package controllerremap;

import sys.FileSystem;
import sys.io.File;

/** One pad binding: button name, hold-modifier id (-1 none) and trigger-mode id (-1 none). */
typedef Pad = controllerremap.Profile.ProfilePad;
typedef Row = {id:String, label:String, text:String, pads:Array<Pad>, planned:String, changed:Bool};

/** Reversible pad binding overrides, profiles and cached editor state.
 * All filesystem access and engine reads run in observe; the UI consumes cached rows.
 */
class Remap {
    public static inline var VERSION="0.1.0";
    public static inline var DIR="hlx/mods/controllerremap";
    public static inline var PROFILES=DIR+"/profiles";
    public static var PADS:Array<String>=["A","B","X","Y","LB","RB","LT","RT","Back","Start","AnalogClick","RanalogClick",
        "DpadUp","DpadDown","DpadLeft","DpadRight","AnalogUp","AnalogDown","AnalogLeft","AnalogRight",
        "RanalogUp","RanalogDown","RanalogLeft","RanalogRight"];
    /** Hold choices: label, modifier id, mode id. Modifier ids: 3=LT 4=LB 5=RT 6=RB. Mode 0=weapon (RT held), 1=class (LT held). */
    public static var HOLD_LABELS:Array<String>=["No hold","Hold LB","Hold RB","Hold LT","Hold RT","Weapon mode hold","Class mode hold"];
    static var HOLD_MOD:Array<Int>=[-1,4,6,3,5,-1,-1];
    static var HOLD_MODE:Array<Int>=[-1,-1,-1,-1,-1,0,1];
    /** The A/B switch only touches these confirm / cancel actions. */
    public static var SWAP_IDS:Array<String>=["Menu_LeftClick","Menu_Back","CloseWindow","AimSkillConfirm"];

    public static var rows(default,null):Array<Row>=[];
    public static var ready(default,null):Bool=false;
    public static var enabled:Bool=true;
    public static var swapAB:Bool=false;
    public static var dirty:Bool=false;
    public static var activeProfile:String="";
    public static var status:String="Starting...";
    public static var profiles(default,null):Array<String>=[];
    public static var overrideCount(get,never):Int;
    static function get_overrideCount():Int {var n=0;for(_ in overrides.keys())n++;return n;}

    static var ids:Array<String>=[];
    static var allIds:Array<String>=[];
    static var native:NativeBindings;
    public static var appliedCount(default,null):Int=0;
    public static var applyFailed(default,null):Bool=false;
    static var baseline:Map<String,Array<Pad>>=new Map();
    static var overrides:Map<String,Array<Pad>>=new Map();
    static var nextTry:Float=0;
    static var nextCheck:Float=0;
    public static var revision(default,null):Int=0;

    // ---------- mapping helpers ----------
    public static function holdIndex(p:Pad):Int {
        for(i in 0...HOLD_LABELS.length) if(HOLD_MOD[i]==p.mod&&HOLD_MODE[i]==p.mode) return i;
        return 0;
    }
    public static function make(padIdx:Int,holdIdx:Int):Pad return {pad:PADS[padIdx],mod:HOLD_MOD[holdIdx],mode:HOLD_MODE[holdIdx]};
    public static function padIndex(name:String):Int {var i=PADS.indexOf(name);return i<0?0:i;}
    static function same(a:Pad,b:Pad):Bool return a.pad==b.pad&&a.mod==b.mod&&a.mode==b.mode;
    public static function samePads(a:Array<Pad>,b:Array<Pad>):Bool {
        if(a.length!=b.length) return false;
        for(i in 0...a.length) if(!same(a[i],b[i])) return false;
        return true;
    }
    public static function text(pads:Array<Pad>):String {
        if(pads.length==0) return "(no pad binding)";
        var out:Array<String>=[];
        for(p in pads){
            var prefix="";
            if(p.mod==3) prefix="LT + "; else if(p.mod==4) prefix="LB + "; else if(p.mod==5) prefix="RT + "; else if(p.mod==6) prefix="RB + ";
            else if(p.mod>=0) prefix="Mod"+p.mod+" + ";
            if(p.mode==0) prefix="Weapon mode + "+prefix; else if(p.mode==1) prefix="Class mode + "+prefix;
            out.push(prefix+p.pad);
        }
        return out.join(" | ");
    }
    static function intField(raw:Dynamic,field:String):Int {
        try {var v:Dynamic=HlxRuntime.resolveField(raw,field);if(v!=null&&Std.isOfType(v,Int)){var i:Int=v;return i;}} catch(_:Dynamic){}
        return -1;
    }
    static function padName(p:Dynamic):String {
        if(p==null) return "";
        try {return (cast p:gamepad.PadInputCode).getConstructorName();} catch(_:Dynamic){}
        return "";
    }
    /** One engine read of an action: its pad entries, and the raw keyboard entries (kept as they are). */
    static function readBoth(id:String,strict:Bool=false):{pads:Array<Pad>,keys:Array<Dynamic>} {
        var pads:Array<Pad>=[];var keys:Array<Dynamic>=[];
        try {
            var list=lib.Input.getBindings(id);
            if(list==null||list.length<0||list.length>32)throw "Unreadable bindings for "+id;
            if(list!=null&&list.length>=0&&list.length<=32){
                // getBindings returns shared scratch storage: copy everything out before the next engine call.
                var raws:Array<Dynamic>=[];for(i in 0...list.length) raws.push(list.getDyn(i));
                for(raw in raws){
                    if(raw==null) continue;
                    var name=padName(HlxRuntime.resolveField(raw,"padCode"));
                    if(name!="") pads.push({pad:name,mod:intField(raw,"modifier"),mode:intField(raw,"mode")});
                    else if(HlxRuntime.resolveField(raw,"code")!=null)keys.push(raw);
                }
            }
        } catch(e:Dynamic){if(strict)throw e;}
        return {pads:pads,keys:keys};
    }
    public static function readPads(id:String,strict:Bool=false):Array<Pad> return readBoth(id,strict).pads;
    public static function keyboardSignature(id:String):String {
        var keys=readBoth(id,true).keys;var values:Array<String>=[];
        for(k in keys)values.push(intField(k,"code")+":"+intField(k,"modifier")+":"+intField(k,"mode"));
        return values.join("|");
    }
    public static function poll(now:Float):Void {
        start(now);
        if(!ready||now<nextCheck)return;
        nextCheck=now+1;
        try {
            if(!native.current()){
                native.restore();native=new NativeBindings();
                for(id in ids)baseline.set(id,readPads(id,true));
                apply();
            }
        }catch(e:Dynamic){applyFailed=true;status="Cannot refresh native input: "+Std.string(e);}
    }

    // ---------- startup / refresh ----------
    /** Retries about once a second until the engine's binding maps are populated. */
    public static function start(now:Float):Void {
        if(ready||now<nextTry) return;
        nextTry=now+1;
        try {
            var seen=new Map<String,Bool>();var all:Array<String>=[];
            for(map in [lib.Input.userBinds,lib.Input.defaultBinds]){
                if(map==null) continue;var keys=map.keys();if(keys==null) continue;var n=0;
                while(keys.hasNext()){
                    if(++n>1024) break;var id=Std.string(keys.next());
                    if(!seen.exists(id)){seen.set(id,true);all.push(id);}
                }
            }
            if(all.length==0) return;
            all.sort(function(a,b)return a<b?-1:(a>b?1:0));
            allIds=all;
            ids=[];baseline=new Map();
            for(id in all){var r=readBoth(id);if(r.pads.length>0){ids.push(id);baseline.set(id,r.pads);}}
            if(ids.length==0) return;
            native=new NativeBindings();
            ready=true;
            refreshRows();
            loadSettings();listProfiles();
            if(activeProfile!="") loadProfile(activeProfile); else apply();
            if(status=="Starting...") status="Ready. "+ids.length+" pad actions found.";
        } catch(e:Dynamic){status="Waiting for the game's input table: "+Std.string(e);}
    }

    public static function refreshRows():Void {
        var out:Array<Row>=[];
        var eff=effective();
        for(id in ids){
            var r=readBoth(id);var wanted=eff.exists(id)?eff.get(id):r.pads;
            out.push({id:id,label:ActionLabels.display(id),text:text(r.pads),pads:r.pads,planned:text(wanted),changed:!samePads(r.pads,wanted)});
        }
        rows=out;revision++;
    }

    /** The pad entries an editor should start from: our override, else what the engine reports now. */
    public static function currentPads(id:String):Array<Pad> {
        if(overrides.exists(id)) return overrides.get(id).copy();
        if(baseline.exists(id))return baseline.get(id).copy();
        for(r in rows) if(r.id==id) return r.pads.copy();
        return [];
    }

    // ---------- reversible controller overrides ----------
    static function swapped(pads:Array<Pad>):Array<Pad> {
        return [for(p in pads) {pad:p.pad=="A"?"B":(p.pad=="B"?"A":p.pad),mod:p.mod,mode:p.mode}];
    }
    static function effective():Map<String,Array<Pad>> {
        var eff=new Map<String,Array<Pad>>();
        for(id in overrides.keys()) eff.set(id,overrides.get(id));
        if(swapAB) for(id in SWAP_IDS) {
            if(eff.exists(id)) eff.set(id,swapped(eff.get(id)));
            else if(baseline.exists(id)) eff.set(id,swapped(baseline.get(id)));
        }
        return eff;
    }

    /** Apply all overrides as one operation; rollback every owned entry on failure. */
    public static function apply():Void {
        if(!ready) return;
        applyFailed=false;
        try {
            if(enabled)native.apply(effective(),allIds);else native.restore();
            appliedCount=native.count;
            status=enabled?"Overrides on. "+appliedCount+" controller actions customized.":"Overrides off. Original game bindings restored.";
        }catch(e:Dynamic){applyFailed=true;appliedCount=native.count;status="Override failed: "+Std.string(e);}
        refreshRows();
    }

    // ---------- edits from the UI ----------
    public static function setOverride(id:String,pads:Array<Pad>):Void {
        if(baseline.exists(id)&&samePads(baseline.get(id),pads)) overrides.remove(id); else overrides.set(id,pads);
        dirty=true;apply();
    }
    public static function resetOverride(id:String):Void {overrides.remove(id);dirty=true;apply();}
    public static function layoutPads(id:String):Array<Pad> {
        var pads=currentPads(id);
        return swapAB&&SWAP_IDS.indexOf(id)>=0?swapped(pads):pads;
    }
    /** Exchange complete configured layouts, then apply them together through the normal rollback path. */
    public static function swapActions(left:String,right:String):Bool {
        if(!ready||left==null||right==null||left==right||!baseline.exists(left)||!baseline.exists(right)){
            status="Choose two different controller actions to swap.";return false;
        }
        var a=layoutPads(left),b=layoutPads(right);
        var before=overrides,wasDirty=dirty;
        var next=new Map<String,Array<Pad>>();for(id in before.keys())next.set(id,before.get(id));
        function put(id:String,pads:Array<Pad>):Void {
            var raw=swapAB&&SWAP_IDS.indexOf(id)>=0?swapped(pads):pads;
            if(samePads(raw,baseline.get(id)))next.remove(id);else next.set(id,raw);
        }
        put(left,b);put(right,a);overrides=next;apply();
        if(applyFailed){
            var reason=status;overrides=before;dirty=wasDirty;apply();
            status="Swap failed. "+(applyFailed?"Previous layout could not be reapplied. ":"Previous layout restored. ")+reason;
            applyFailed=true;return false;
        }
        dirty=true;status="Swapped "+ActionLabels.display(left)+" and "+ActionLabels.display(right)+". "+status;
        return true;
    }
    public static function clearAll():Void {overrides=new Map();swapAB=false;activeProfile="";dirty=true;apply();saveSettings();}
    public static function setEnabled(v:Bool):Void {enabled=v;apply();saveSettings();}
    public static function setSwap(v:Bool):Void {swapAB=v;dirty=true;apply();}

    // ---------- profiles & settings (plain JSON files; share them by copying the file) ----------
    static function ensureDir():Bool {
        try {
            for(d in ["hlx","hlx/mods",DIR,PROFILES]) if(!FileSystem.exists(d)) FileSystem.createDirectory(d);
            return true;
        } catch(_:Dynamic){return false;}
    }
    public static function cleanName(raw:String):String {
        var out=new StringBuf();
        for(i in 0...raw.length){
            var c=raw.charCodeAt(i);
            if((c>=48&&c<=57)||(c>=65&&c<=90)||(c>=97&&c<=122)||c==32||c==45||c==95) out.addChar(c);
        }
        var s=StringTools.trim(out.toString());
        return s.length>40?s.substr(0,40):s;
    }
    public static function listProfiles():Void {
        var out:Array<String>=[];
        try {
            if(FileSystem.exists(PROFILES)) for(f in FileSystem.readDirectory(PROFILES))
                if(StringTools.endsWith(f,".json")&&out.length<200&&!FileSystem.isDirectory(PROFILES+"/"+f)&&Profile.validName(f.substr(0,f.length-5))) out.push(f.substr(0,f.length-5));
            out.sort(function(a,b)return a<b?-1:(a>b?1:0));
        } catch(_:Dynamic){}
        profiles=out;
    }
    static function entries(pads:Array<Pad>):Array<Dynamic> return [for(p in pads) {pad:p.pad,modifier:p.mod,mode:p.mode}];

    public static function saveProfile(raw:String):Void {
        var name=cleanName(raw);
        if(!Profile.validName(name)){status="Use a profile name with letters, numbers, space, - or _. Windows device names are reserved.";return;}
        if(!ensureDir()){status="Could not create "+PROFILES;return;}
        try {
            var actions:Array<Dynamic>=[];
            var keys=[for(k in overrides.keys()) k];keys.sort(function(a,b)return a<b?-1:(a>b?1:0));
            for(id in keys) actions.push({action:id,entries:entries(overrides.get(id))});
            atomicWrite(PROFILES+"/"+name+".json",haxe.Json.stringify({format:"controllerremap.profile.v1",name:name,swapConfirmCancel:swapAB,actions:actions},null,"  "));
            activeProfile=name;dirty=false;listProfiles();
            status="Saved profile \""+name+"\" ("+actions.length+" customized action"+(actions.length==1?"":"s")+").";
            saveSettings();
        } catch(e:Dynamic){status="Save failed: "+Std.string(e);}
    }

    public static function loadProfile(raw:String):Void {
        var name=cleanName(raw);
        try {
            if(!Profile.validName(name)||name!=raw) throw "invalid filename";
            var path=PROFILES+"/"+name+".json";
            if(FileSystem.stat(path).size>Profile.MAX_BYTES) throw "profile is too large";
            var parsed=Profile.decode(File.getContent(path),ids,PADS);
            overrides=parsed.actions;swapAB=parsed.swap;
            activeProfile=name;dirty=false;apply();
            status="Loaded \""+name+"\"."+(parsed.skipped>0?" Skipped "+parsed.skipped+" unknown actions.":"")+" "+status;
            saveSettings();
        } catch(e:Dynamic){status="Could not load \""+name+"\": "+Std.string(e);}
    }

    /** Remove a saved file; the current in-memory layout remains available to save again. */
    public static function deleteProfile(raw:String):Bool {
        try {
            if(raw==null||!Profile.validName(raw)||cleanName(raw)!=raw)throw "invalid profile name";
            var path=PROFILES+"/"+raw+".json";
            if(!FileSystem.exists(path)||FileSystem.isDirectory(path))throw "profile file not found";
            FileSystem.deleteFile(path);
            if(FileSystem.exists(path))throw "profile file still exists";
            var wasActive=activeProfile.toLowerCase()==raw.toLowerCase();
            if(wasActive){activeProfile="";dirty=true;}
            listProfiles();
            status="Deleted profile \""+raw+"\"."+(wasActive?" The current layout is kept as unsaved changes.":"");
            if(wasActive)saveSettings();
            return true;
        }catch(e:Dynamic){status="Could not delete profile: "+Std.string(e);return false;}
    }

    static function saveSettings():Void {
        try {
            if(!ensureDir())throw "Cannot create settings folder";
            atomicWrite(DIR+"/settings.json",haxe.Json.stringify({enabled:enabled,profile:activeProfile},null,"  "));
        }catch(e:Dynamic){status+=" Could not save startup settings: "+Std.string(e);}
    }
    static function atomicWrite(path:String,content:String):Void {
        SafeFile.write(path,content);
    }
    static function loadSettings():Void {
        try {
            var p=DIR+"/settings.json";if(!FileSystem.exists(p)) return;
            var d:Dynamic=haxe.Json.parse(File.getContent(p));
            enabled=Reflect.field(d,"enabled")!=false;
            var n:Dynamic=Reflect.field(d,"profile");
            if(Std.isOfType(n,String)) activeProfile=cleanName(n);
        } catch(_:Dynamic){}
    }

}
