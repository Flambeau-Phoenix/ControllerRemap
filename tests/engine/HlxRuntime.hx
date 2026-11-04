/** Offline fixture only: matches the bridge's field access and enum resolution. */
class HlxRuntime {
    public static function resolveType(s:String):String return s;
    public static function resolveField(o:Dynamic,k:String):Dynamic return Reflect.field(o,k);
    public static function resolveStaticField(t:String,k:String):Dynamic return Type.createEnum(FakePadCode,k);
}
enum FakePadCode { A; B; X; Y; LB; RB; LT; RT; Back; Start; AnalogClick; RanalogClick; DpadUp; DpadDown; DpadLeft; DpadRight; }
