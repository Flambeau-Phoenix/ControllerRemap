package gamepad;
abstract PadInputCode(Dynamic) {
    public inline function getConstructorName():String return Type.enumConstructor(cast this);
}
