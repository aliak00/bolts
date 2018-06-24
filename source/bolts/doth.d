/**
    Doth is doth is is - reason for choosing doth is because is is a keyword
*/
module bolts.doth;

import bolts.internal;

import std.traits;
import std.meta;

/**
    Doth is a helper template that allows you to inspect a type or an alias.

    It takes a single element as an argument. The reason the template parameters is
    types as a variable arg sequence is becure if D does not allow to say "I want either
    a type of alias over here, I don't care, I'll figure it out". But it does allow it
    when you use a $(I template sequence parameter)
    
    See_also:
        - https://dlang.org/spec/template.html#variadic-templates
*/
template doth(Types...) if (Types.length == 1) {
    import bolts.meta: TypesOf;
    alias T = TypesOf!Types[0];

    /// True if the resolved type nullable
    enum nullable = __traits(compiles, { T t = null; t = null; });

    /// True if the resolved type is typeof(null)
    enum nullType = is(T == typeof(null));

    /// True if the resolved type is the same as another resolved type
    static template of(OtherTypes...) if (OtherTypes.length == 1) {
        alias U = TypesOf!OtherTypes[0];
        enum of = is(T == U);
    }
}

///
unittest {
    int i = 3;
    int *pi = null;

    static assert( doth!i.of!int);
    static assert(!doth!i.of!(int*));
    static assert( doth!int.of!i);
    static assert(!doth!int.of!pi);

    static assert( doth!pi.nullable);
    static assert( doth!(char*).nullable);
    static assert(!doth!i.nullable);
    static assert(!doth!int.nullable);

    static assert(!doth!int.nullType);
    static assert( doth!null.nullType);
    static assert( doth!(typeof(null)).nullType);
}

unittest {
    class C {}
    struct S {}
    struct S1 {
        this(typeof(null)) {}
        void opAssign(typeof(null)) {}
    }

    static assert( doth!C.nullable);
    static assert(!doth!S.nullable);
    static assert( doth!S1.nullable);
    static assert( doth!(int *).nullable);
    static assert(!doth!(int).nullable);
}

unittest {
    int a;
    int *b = null;
    struct C {}
    C c;
    void f() {}
    static assert( doth!null.nullType);
    static assert(!doth!a.nullType);
    static assert(!doth!b.nullType);
    static assert(!doth!c.nullType);
    static assert(!doth!f.nullType);
}

unittest {
    import std.meta: allSatisfy, AliasSeq;
    static assert(doth!int.of!3);
    static assert(allSatisfy!(doth!int.of, 3));
}