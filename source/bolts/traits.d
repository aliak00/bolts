/**
    Provides utilites that allow you to determine type traits
*/
module bolts.traits;

import bolts.internal;

/**
    Returns the types of all values given.

    $(OD isFunction!T then the typeof the address is taken if possible)
    $(OD If typeof(T) can be taken it is)
    $(OD Else it is appended on as is)

    Returns:
        AliasSeq of the resulting types
*/
template TypesOf(Values...) {
    import std.meta: AliasSeq;
    import std.traits: isExpressions, isFunction;
    static if (Values.length) {
        static if (isFunction!(Values[0]) && is(typeof(&Values[0]) F)) {
            alias T = F;
        } else static if (is(typeof(Values[0]))) {
            alias T = typeof(Values[0]);
        } else {
            alias T = Values[0];
        }
        alias TypesOf = AliasSeq!(T, TypesOf!(Values[1..$]));
    } else {
        alias TypesOf = AliasSeq!();
    }
}

///
unittest {
    import std.meta: AliasSeq;
    static assert(is(TypesOf!("hello", 1, 2, 3.0, real) == AliasSeq!(string, int, int, double, real)));
}

unittest {
    import std.meta: AliasSeq;
    static void f0() {}
    void f1() {}
    struct S { void f2() {} }
    static assert(is(TypesOf!(f0, f1, S.f2) == AliasSeq!(typeof(&f0), typeof(&f1), typeof(&S.f2))));
}

unittest {
    import std.meta: AliasSeq;
    int f(int p) { return 3; }
    static assert(is(TypesOf!(typeof(f)) == AliasSeq!(typeof(f))));
}

///
unittest {
    class C {}
    struct S {}
    struct S1 {
        this(typeof(null)) {}
        void opAssign(typeof(null)) {}
    }

    static assert( isNullable!C);
    static assert(!isNullable!S);
    static assert( isNullable!S1);
    static assert( isNullable!(int *));
    static assert(!isNullable!(int));
}

/**
    Returns true if the first argument is a n-ary function over the next n parameter arguments

    Parameter arguments can be any compile time entity that can be typed
*/
template isFunctionOver(T...) {
    import std.meta: staticMap, Alias;
    import std.traits: isSomeFunction, Parameters;
    import bolts.meta: AliasPack, staticZip;
    import bolts.traits: TypesOf;

    alias Types = TypesOf!T;

    static if (Types.length >= 1) {
        alias DesiredParams = AliasPack!(Types[1 .. $]);
        static if (isSomeFunction!(Types[0])) {
            alias ExpectedParams = AliasPack!(Parameters!(Types[0]));
            static if (DesiredParams.length == ExpectedParams.length) {
                static if (DesiredParams.length == 0) {
                    enum isFunctionOver = true;
                } else {
                    import std.meta: allSatisfy;
                    alias Pairs = staticZip!(ExpectedParams, DesiredParams);
                    enum AreSame(alias pair) = is(pair.expand[0] == pair.expand[1]);
                    enum isFunctionOver = allSatisfy!(AreSame, Pairs.expand);
                }
            } else {
                enum isFunctionOver = false;
            }
        } else static if (is(Types[0] == void)) {
            // We're going to assume the first arg is a function literal ala lambda
            // And try and see if calling it with the init values of the desired
            // params works
            alias F = T[0];
            alias Val(T) = Alias!(T.init);
            enum isFunctionOver = __traits(compiles, { F(staticMap!(Val, DesiredParams.expand)); });
        } else {
            enum isFunctionOver = false;
        }
    } else {
        enum isFunctionOver = false;
    }
}

///
unittest {
    int v;
    void f0() {}
    void f1(int a) {}
    void f2(int a, string b) {}
    void f3(int a, string b, float c) {}

    static assert( isFunctionOver!(f0));
    static assert(!isFunctionOver!(f0, int));

    static assert(!isFunctionOver!(f1, string));
    static assert( isFunctionOver!(f1, int));

    static assert(!isFunctionOver!(f2, int));
    static assert( isFunctionOver!(f2, int, string));
    static assert(!isFunctionOver!(f2, int, float));
    static assert(!isFunctionOver!(f2, int, float, string));

    static assert(!isFunctionOver!(f3, int, float, string));
    static assert(!isFunctionOver!(f3, int, float));
    static assert(!isFunctionOver!(f3, int));
    static assert(!isFunctionOver!(f3));
    static assert( isFunctionOver!(f3, int, string, float));

    struct A {}
    static assert(!isFunctionOver!(a => a, float, int));
    static assert( isFunctionOver!(a => a, float));
    static assert( isFunctionOver!(a => a, int));
    static assert(!isFunctionOver!((int a) => a, float));
    static assert(!isFunctionOver!(a => a));
    static assert( isFunctionOver!((a, b) => a + b, float, int));
    static assert(!isFunctionOver!((a, b) => a + b, A, int));
    static assert( isFunctionOver!((a, b, c, d) => a+b+c+d, int, int, int ,int));
}


/**
    Returns true if the first argument is a unary function over the next parameter arguments

    Parameter arguments can be any compile time entity that can be typed

    It uses `std.function.unaryFun` so it can take a string representation of a function as well
*/
template isUnaryOver(T...) {
    import std.functional: unaryFun;
    static if (T.length == 2) {
        enum isUnaryOver = isFunctionOver!T || is(typeof(unaryFun!(T[0])(T[1].init)));
    } else {
        enum isUnaryOver = false;
    }
}

///
unittest {
    int v;
    void f0() {}
    void f1(int a) {}
    void f2(int a, int b) {}

    static assert( isUnaryOver!("a", int));
    static assert( isUnaryOver!("a > a", int));
    static assert(!isUnaryOver!("a > b", int));
    static assert(!isUnaryOver!(null, int));
    static assert( isUnaryOver!((a => a), int));
    static assert(!isUnaryOver!((a, b) => a + b, int));

    static assert(!isUnaryOver!(v, int));
    static assert(!isUnaryOver!(f0, int));
    static assert( isUnaryOver!(f1, int));
    static assert(!isUnaryOver!(f2, int));

    import std.math: ceil;
    static assert( isUnaryOver!(ceil, double));
    static assert(!isUnaryOver!(ceil, double, double));

    static assert( isUnaryOver!(f1, 3));
    static assert(!isUnaryOver!(f1, "ff"));
    static assert( isUnaryOver!("a", 3));
    static assert(!isUnaryOver!(f1, 3, 4));
    static assert( isUnaryOver!(typeof(f1), 3));
    static assert(!isUnaryOver!(typeof(f1), "ff"));
}

/**
    Returns true if the first argument is a binary function over the next two parameter arguments

    Parameter arguments can be any compile time entity that can be typed

    It uses `std.function.binaryFun` as well so it can take a string representation of a function as well
*/
template isBinaryOver(T...) {
    import std.functional: binaryFun;
    static if (T.length == 3) {
        enum isBinaryOver = isFunctionOver!T || is(typeof(binaryFun!(T[0])(T[1].init, T[2].init)));
    } else {
        enum isBinaryOver = false;
    }
}

///
unittest {
    int v;
    void f0() {}
    void f1(int a) {}
    void f2(int a, int b) {}

    import std.functional: binaryFun;

    static assert(!isBinaryOver!("a", int));
    static assert(!isBinaryOver!("a > a", int));
    static assert(!isBinaryOver!("a > b", int));
    static assert(!isBinaryOver!(null, int));
    static assert(!isBinaryOver!((a => a), int));
    static assert(!isBinaryOver!((a, b) => a + b, int));
    static assert( isBinaryOver!((a, b) => a + b, int, int));

    static assert(!isBinaryOver!(v, int));
    static assert(!isBinaryOver!(f0, int));
    static assert(!isBinaryOver!(f1, int));
    static assert(!isBinaryOver!(f2, int));
    static assert( isBinaryOver!(f2, int, int));
    static assert(!isBinaryOver!(f2, int, string));
    static assert(!isBinaryOver!(f2, int, int, int));

    static assert(!isBinaryOver!("a > b", 3));
    static assert( isBinaryOver!("a > b", 3, 3));
    static assert( isBinaryOver!("a > b", 3, int));
}

/**
    Tells you if a list of types, which are composed of ranges and non ranges,
    share a common type after flattening the ranges (i.e. `ElementType`)

    This basically answers the question: $(Can I combine these ranges and values
    into a single range of a common type?)

    See_also:
        `bolts.meta.FlattenRanges`
*/
template areCombinable(Values...) {
    import std.traits: CommonType;
    import bolts.meta: FlattenRanges;
    enum areCombinable = !is(CommonType!(FlattenRanges!Values) == void);
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
    Tells you if a name is a member and property in a type
*/
auto hasProperty(T, string name)() {
    import std.traits: hasMember;
    static if (hasMember!(T, name)) {
        return !is(typeof(__traits(getMember, T, name)) == function)
		    && __traits(getOverloads, T, name).length;
    } else {
        return false;
    }
}

///
unittest {
    struct S {
        int m;
        static int sm;
        void f() {}
        static void sf() {}
        @property int rp() { return m; }
        @property void wp(int) {}
    }

    static assert(!hasProperty!(S, "na"));
    static assert(!hasProperty!(S, "m"));
    static assert(!hasProperty!(S, "sm"));
    static assert(!hasProperty!(S, "f"));
    static assert(!hasProperty!(S, "sf"));
    static assert( hasProperty!(S, "rp"));
    static assert( hasProperty!(S, "wp"));
}

/**
    Tells you if a name is a read and/or write property

    Returns:
        `Tuple!(bool, "isRead", bool, "isWrite")`
*/
auto propertySemantics(T, string name)() if (hasProperty!(T, name)) {
    import std.typecons: tuple;
    enum overloads = __traits(getOverloads, T, name).length;
    enum canInstantiateAsField = is(typeof(mixin("T.init." ~ name)));
    static if (overloads > 1 || canInstantiateAsField)
        enum canRead = true;
    else
        enum canRead = false;
    static if (overloads > 1 || !canInstantiateAsField)
        enum canWrite = true;
    else
        enum canWrite = false;
    return tuple!("canRead", "canWrite")(canRead, canWrite);
}

///
unittest {
    import std.typecons;
    struct S {
        int m;
        @property int rp() { return m; }
        @property void wp(int) {}
        @property int rwp() { return m; }
        @property void rwp(int) {}
    }

    static assert(!__traits(compiles, propertySemantics!(S, "na")));
    static assert(!__traits(compiles, propertySemantics!(S, "m")));
    static assert(propertySemantics!(S, "rp") == tuple!("canRead", "canWrite")(true, false));
    static assert(propertySemantics!(S, "wp") == tuple!("canRead", "canWrite")(false, true));
    static assert(propertySemantics!(S, "rwp") == tuple!("canRead", "canWrite")(true, true));
}

/**
    Returns true if T.name is a manifest constant, built-in type field, or immutable static
*/
template isManifestAssignable(T, string name) {
    enum isManifestAssignable = is(typeof({ enum x = mixin("T." ~ name); }));
}

///
unittest {
    struct A {
        int m;
        static immutable int sim = 1;
        enum e = 1;
    }

    static assert(!isManifestAssignable!(A*, "na"));
    static assert(!isManifestAssignable!(A, "na"));
    static assert(!isManifestAssignable!(A, "m"));
    static assert( isManifestAssignable!(A, "e"));
    static assert( isManifestAssignable!(A, "sim"));
}

/**
    Can be used to construct a meta function that checks if a symbol is of a type.
*/
template isType(T) {
    auto isType(U)(U) { return is(U == T); }
    enum isType(alias a) = isType!T(a);
}

///
unittest {
    import std.meta: allSatisfy, AliasSeq;
    static assert(isType!int(3));
    static assert(allSatisfy!(isType!int, 3));
    static assert(allSatisfy!(isType!int, 3));
}

/// True if a is of type null
template isNullType(T...) if (T.length == 1) {
    import bolts.traits: TypesOf;
    alias U = TypesOf!T[0];
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
    Returns true of T can be set to null
*/
template isNullable(T...) if (T.length == 1) {
    import bolts.traits: TypesOf;
    alias U = TypesOf!T[0];
    enum isNullable = __traits(compiles, { U u = null; u = null; });
}

/**
    Returns true if a and b are the same thing, or false if not. Both a and b can be types, literals, or symbols.

    $(LI If both are types: `is(a == b)`)
    $(LI If both are literals: `a == b`)
    $(LI Else: `__traits(isSame, a, b)`)
*/
template isSame(ab...) if (ab.length == 2) {

    private static template expectType(T) {}
    private static template expectBool(bool b) {}

    static if (__traits(compiles, expectType!(ab[0]), expectType!(ab[1]))) {
        enum isSame = is(ab[0] == ab[1]);
    } else static if (!__traits(compiles, expectType!(ab[0]))
        && !__traits(compiles, expectType!(ab[1]))
        &&  __traits(compiles, expectBool!(ab[0] == ab[1]))
    ) {
        static if (!__traits(compiles, &ab[0]) || !__traits(compiles, &ab[1]))
            enum isSame = (ab[0] == ab[1]);
        else
            enum isSame = __traits(isSame, ab[0], ab[1]);
    } else {
        enum isSame = __traits(isSame, ab[0], ab[1]);
    }
}

///
unittest {
    static assert( isSame!(int, int));
    static assert(!isSame!(int, short));

    enum a = 1, b = 1, c = 2, s = "a", t = "a";
    static assert( isSame!(1, 1));
    static assert( isSame!(a, 1));
    static assert( isSame!(a, b));
    static assert(!isSame!(b, c));
    static assert( isSame!("a", "a"));
    static assert( isSame!(s, "a"));
    static assert( isSame!(s, t));
    static assert(!isSame!(s, "g"));
    static assert(!isSame!(1, "1"));
    static assert(!isSame!(a, "a"));
    static assert( isSame!(isSame, isSame));
    static assert(!isSame!(isSame, a));

    static assert(!isSame!(byte, a));
    static assert(!isSame!(short, isSame));
    static assert(!isSame!(a, int));
    static assert(!isSame!(long, isSame));

    static immutable X = 1, Y = 1, Z = 2;
    static assert( isSame!(X, X));
    static assert(!isSame!(X, Y));
    static assert(!isSame!(Y, Z));

    int  foo();
    int  bar();
    real baz(int);
    static assert( isSame!(foo, foo));
    static assert(!isSame!(foo, bar));
    static assert(!isSame!(bar, baz));
    static assert( isSame!(baz, baz));
    static assert(!isSame!(foo, 0));

    int  x, y;
    real z;
    static assert( isSame!(x, x));
    static assert(!isSame!(x, y));
    static assert(!isSame!(y, z));
    static assert( isSame!(z, z));
    static assert(!isSame!(x, 0));
}
