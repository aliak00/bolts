/**
    Traits that can query type information about stuff.
*/
module bolts.traits.types;

import bolts.internal;

/// True if `T` is of type null
template isNullType(T...) if (T.length == 1) {
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isNullType = is(U == typeof(null));
}

///
unittest {
    int a;
    int *b = null;
    struct C {}
    C c;
    void f() {}
    static assert(isNullType!null);
    static assert(isNullType!a == false);
    static assert(isNullType!b == false);
    static assert(isNullType!c == false);
    static assert(isNullType!f == false);
}

/**
    Checks if a compile time entity is a reference type.
*/
template isRefType(T...) if (T.length == 1) {
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isRefType = is(U == class) || is(U == interface);
}

///
unittest {
    struct S {}
    class C {}
    static assert(!isRefType!S);
    static assert(!isRefType!int);
    static assert( isRefType!C);
}

/**
    Checks if a compile time entity is a value type
*/
enum isValueType(T...) = !isRefType!T;

///
unittest {
    struct S {}
    class C {}
    static assert( isValueType!int);
    static assert( isValueType!(int*));
    static assert( isValueType!S);
    static assert(!isValueType!C);
}

/**
    Checks to see if a type is copy constructable - postblit doesn't count.

    Returns false if there's a user defined postblit.
*/
template isCopyConstructable(T...) if (T.length == 1) {
    import std.traits: hasMember;
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isCopyConstructable
        = __traits(compiles, { auto r = U.init; U copy = r; })
        && !hasMember!(U, "__xpostblit");
}

///
unittest {
    mixin copyConstructableKinds;

    static assert( isCopyConstructable!KindPOD);
    static assert( isCopyConstructable!KindHasCopyContrustor);
    static assert(!isCopyConstructable!KindHasPostBlit);
    static assert( isCopyConstructable!KindContainsPOD);
    static assert( isCopyConstructable!KindContainsTypeWithNonTrivialCopyConstructor);
    static assert(!isCopyConstructable!KindContainsTypeWithPostBlit);
}

/**
    Checks to see if a type is non-trivially copy constructable

    This does not check for postblits
*/
template isNonTriviallyCopyConstructable(T...) if (T.length == 1) {
    import std.traits: hasMember;
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isNonTriviallyCopyConstructable
        = isCopyConstructable!U
        && hasMember!(U, "__ctor");
}

///
unittest {
    mixin copyConstructableKinds;

    static assert(!isNonTriviallyCopyConstructable!KindPOD);
    static assert( isNonTriviallyCopyConstructable!KindHasCopyContrustor);
    static assert(!isNonTriviallyCopyConstructable!KindHasPostBlit);
    static assert(!isNonTriviallyCopyConstructable!KindContainsPOD);
    static assert( isNonTriviallyCopyConstructable!KindContainsTypeWithNonTrivialCopyConstructor);
    static assert(!isNonTriviallyCopyConstructable!KindContainsTypeWithPostBlit);
}

/**
    Checks if a type is trivially constructable, that is no user-defined copy constructor exists - postblit doesn't count.
*/
template isTriviallyCopyConstructable(T...) if (T.length == 1) {
    import std.traits: hasMember;
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isTriviallyCopyConstructable
        = isCopyConstructable!U
        && !hasMember!(U, "__ctor");
}

///
unittest {
    mixin copyConstructableKinds;

    static assert( isTriviallyCopyConstructable!KindPOD);
    static assert(!isTriviallyCopyConstructable!KindHasCopyContrustor);
    static assert(!isTriviallyCopyConstructable!KindHasPostBlit);
    static assert( isTriviallyCopyConstructable!KindContainsPOD);
    static assert(!isTriviallyCopyConstructable!KindContainsTypeWithNonTrivialCopyConstructor);
    static assert(!isTriviallyCopyConstructable!KindContainsTypeWithPostBlit);
}

/**
    Tells you if a list of types, which are composed of ranges and non ranges,
    share a common type after flattening the ranges (i.e. `ElementType`)

    This basically answers the question: $(Can I combine these ranges and values
    into a single range of a common type?)

    See_also:
        `bolts.meta.Flatten`
*/
template areCombinable(Values...) {
    import std.traits: CommonType;
    import bolts.meta: Flatten;
    enum areCombinable = !is(CommonType!(Flatten!Values) == void);
}

///
unittest {
    static assert(areCombinable!(int, int, int));
    static assert(areCombinable!(float[], int, char[]));
    static assert(areCombinable!(string, int, int));
    // Works with string because:
    import std.traits: CommonType;
    import std.range: ElementType;
    static assert(is(CommonType!(ElementType!string, int) == uint));

    struct A {}
    static assert(!areCombinable!(A, int, int));
    static assert(!areCombinable!(A[], int[]));
    static assert( areCombinable!(A[], A[]));
    static assert( areCombinable!(A[], A[], A));
    static assert(!areCombinable!(int[], A));
}

/**
    Returns true if two things are equatable
*/
template areEquatable(T...) if (T.length == 2) {
    private alias ResolvedTypes = from.bolts.traits.symbols.TypesOf!T;
    enum areEquatable = is(typeof(ResolvedTypes[0].init == ResolvedTypes[1].init));
}

///
unittest {
    static assert( areEquatable!(1, 2));
    static assert(!areEquatable!(1, "yo"));
    static assert(!areEquatable!(int, "yo"));
    static assert( areEquatable!(int, 1));
}

/**
    Returns true of T can be check with null using an if statement
*/
template isNullTestable(T...) if (T.length == 1) {
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isNullTestable = __traits(compiles, { if (U.init is null) {} });
}

///
unittest {
    class C {}
    struct S1 {
        void opAssign(int*) {}
    }
    static assert(!isNullTestable!S1);
    static assert( isNullTestable!C);
    static assert( isNullTestable!(int*));

    struct S2 {}
    static assert(!isNullTestable!S2);
    static assert(!isNullTestable!int);

    class C2 {
        @disable this();
    }
    static assert(isNullTestable!C2);
}

deprecated("use isNullSettable instead")
template isNullable(T...) if (T.length == 1) {
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isNullable = __traits(compiles, { U u = U.init; u = null; });
}

/**
    Returns true of T can be set to null
*/
template isNullSettable(T...) if (T.length == 1) {
    alias U = from.bolts.traits.symbols.TypesOf!T[0];
    enum isNullSettable = __traits(compiles, { U u = U.init; u = null; });
}

///
unittest {
    class C {}
    struct S1 {
        void opAssign(int*) {}
    }
    static assert(isNullSettable!S1);
    static assert(isNullSettable!C);
    static assert(isNullSettable!(int*));

    struct S2 {}
    static assert(!isNullSettable!S2);
    static assert(!isNullSettable!int);

    struct S3 {
        @disable this();
        void opAssign(int*) {}
    }
    static assert(isNullSettable!S3);
}

/**
    Returns a stringof another template with it's real and non-mangled types

    You may also customize the format in the case of templates:

    ---
    struct S(T, U) {}
    StringOf!(S!(int, int)).writeln; // "S!(int, int)"
    StringOf!(S!(int, int), "...", "<", ">").writeln; // "S<int...int>"
    ---

    Params:
        T = the type you want to stringize
        sep = in case of a template, what's the deperator between types
        beg = in case of a template, what token marks the beginnig of the template arguments
        end = in case of a template, what token marks the end of the template arguments

    See_Also:
        - https://forum.dlang.org/post/iodgpllgtcefcncoghri@forum.dlang.org
*/
template StringOf(alias U, string sep = ", ", string beg = "!(", string end = ")") {
    import std.traits: TemplateOf;
    static if (__traits(compiles, TemplateOf!U) && !is(TemplateOf!U == void)) {
        import std.traits: TemplateArgsOf;
        import std.string: indexOf;
        import std.conv: text;
        import std.meta: AliasSeq, staticMap;
        alias Tmp = TemplateOf!U;
        alias Args = TemplateArgsOf!U;
        enum tmpFullName = Tmp.stringof;
        enum tmpName = tmpFullName[0..tmpFullName.indexOf('(')];

        alias AddCommas(U...) = AliasSeq!(U, sep);
        alias ArgNames = staticMap!(.StringOf, Args);
        static if (ArgNames.length == 0) {
            alias SeparatedArgNames = AliasSeq!();
        } else {
            alias SeparatedArgNames = staticMap!(AddCommas, ArgNames)[0 .. $-1];
        }
        immutable StringOf = text(tmpName, beg, SeparatedArgNames, end);
    } else {
        static if (__traits(compiles, U.stringof)) {
            immutable StringOf = U.stringof;
        } else {
            immutable StringOf = typeof(U).stringof;
        }
    }
}

/// Ditto
string StringOf(T, string sep = ", ", string beg = "!(", string end = ")")() if (is(TemplateOf!T == void)) {
    return T.stringof;
}

///
unittest {
    template A(T...) {}
    struct B {}
    struct C {}
    alias T = A!(A!(B, C));
    assert(StringOf!T == "A!(A!(B, C))");

    struct S(T) {}
    assert(StringOf!(S!int) == "S!(int)");
    assert(StringOf!(A!(A!(B, S!int))) == "A!(A!(B, S!(int)))");

    assert(StringOf!int == "int");
    assert(StringOf!3 == "3");

    void f(int a, int b) {}
    import std.algorithm: canFind;
    assert(StringOf!(f).canFind("void(int a, int b)"));

    assert(StringOf!void == "void");
}

unittest {
    import std.meta: AliasSeq;
    import bolts.meta: AliasPack;
    alias T = AliasPack!(AliasSeq!());
    assert(StringOf!T == "AliasPack!()");
}

