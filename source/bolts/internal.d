module bolts.internal;

public import bolts.from;

package template ResolvePointer(T) {
    import std.traits: isPointer, PointerTarget;
    static if (isPointer!T) {
        alias ResolvePointer = PointerTarget!T;
    } else {
        alias ResolvePointer = T;
    }
}

version (unittest) {
    // Just here so can be used in unittests without importing all the time
    package import std.stdio: writeln;

    // Defines a set of types that can be used to test copy constructable related traits
    package mixin template copyConstructableKinds() {
        static struct KindPOD {}
        static struct KindHasCopyContrustor { this(ref inout typeof(this)) inout {} }
        static struct KindHasPostBlit { this(this) {} }
        static struct KindContainsPOD { KindPOD value; }
        static struct KindContainsTypeWithNonTrivialCopyConstructor { KindHasCopyContrustor value; }
        static struct KindContainsTypeWithPostBlit { KindHasPostBlit value; }

        static assert(__traits(isPOD, KindPOD));
    }
}
