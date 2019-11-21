/**
    Provides utilites that allow you to determine type traits
*/
module bolts.traits;

import bolts.internal;
import std.traits : TemplateOf;
import std.traits : hasMember;

///
unittest {
    class C {}
    struct S {}
    struct S1 {
        this(typeof(null)) {}
        void opAssign(typeof(null)) {}
    }

    static assert( isNullSettable!C);
    static assert(!isNullSettable!S);
    static assert( isNullSettable!S1);
    static assert( isNullSettable!(int *));
    static assert(!isNullSettable!(int));
}

/**
    Returns true if the passed in function is an n-ary function over the next n parameter arguments

    Parameter arguments can be any compile time entity that can be typed.

    Params:
        T = The first argument is the function to check, the second are the types it should be called over
*/
template isFunctionOver(T...) {
    import std.meta: staticMap, Alias;
    import std.traits: isSomeFunction, Parameters;
    import bolts.meta: AliasPack, staticZip, TypesOf;

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
                    // If is(DesiredType : ExpectedType)
                    enum AreSame(alias Pair) = is(Pair.Unpack[1] : Pair.Unpack[0]);
                    enum isFunctionOver = allSatisfy!(AreSame, Pairs.Unpack);
                }
            } else {
                enum isFunctionOver = false;
            }
        } else static if (is(Types[0] == void)) {
            // We're going to assume the first arg is a function literal ala lambda
            // And try and see if calling it with the init values of the desired
            // params works
            alias F = T[0];
            alias Val(U) = Alias!(U.init);
            enum isFunctionOver = __traits(compiles, {
                auto tup = staticMap!(Val, DesiredParams.Unpack).init;
                F(tup);
            });
        } else {
            enum isFunctionOver = false;
        }
    } else {
        enum isFunctionOver = false;
    }
}

///
unittest {
    int i;
    float f;
    void f0() {}
    void f1(int a) {}
    void f2(int a, string b) {}
    void f3(int a, string b, float c) {}

    static assert( isFunctionOver!(f0));
    static assert(!isFunctionOver!(f0, int));

    static assert(!isFunctionOver!(f1, string));
    static assert( isFunctionOver!(f1, int));
    static assert( isFunctionOver!(f1, i));
    static assert(!isFunctionOver!(f1, f));

    static assert(!isFunctionOver!(f2, int));
    static assert( isFunctionOver!(f2, int, string));
    static assert(!isFunctionOver!(f2, int, float));
    static assert(!isFunctionOver!(f2, int, float, string));

    static assert( isFunctionOver!(f3, int, string, float));
    static assert(!isFunctionOver!(f3, int, float, string));
    static assert(!isFunctionOver!(f3, int, float));
    static assert(!isFunctionOver!(f3, int));
    static assert(!isFunctionOver!(f3));

    static assert( isFunctionOver!(() => 3));
    static assert(!isFunctionOver!(() => 3, int));
    static assert(!isFunctionOver!(a => a, float, int));
    static assert( isFunctionOver!(a => a, float));
    static assert( isFunctionOver!(a => a, int));
    static assert( isFunctionOver!((int a) => a, short));
    static assert(!isFunctionOver!((int a) => a, float));
    static assert(!isFunctionOver!(a => a));
    static assert( isFunctionOver!((a, b) => a + b, float, int));

    struct A {}
    static assert(!isFunctionOver!((a, b) => a + b, A, int));
    static assert( isFunctionOver!((a, b, c, d) => a+b+c+d, int, int, int ,int));

    import std.functional: unaryFun;
    static assert( isFunctionOver!(unaryFun!"a", int));
    static assert(!isFunctionOver!(unaryFun!"a", int, int));

    import std.functional: binaryFun;
    static assert(!isFunctionOver!(binaryFun!"a", int));
    static assert( isFunctionOver!(binaryFun!"a", int, int));
    static assert( isFunctionOver!(binaryFun!"a > b", int, int));
    static assert(!isFunctionOver!(binaryFun!"a > b", int, int, int));

    class C {}
    class D : C {}
    void fc(C) {}
    void fd(D) {}
    static assert( isFunctionOver!(fc, C));
    static assert( isFunctionOver!(fc, D));
    static assert(!isFunctionOver!(fd, C));
    static assert( isFunctionOver!(fd, D));

    import std.math: ceil;
    static assert( isFunctionOver!(ceil, double));
    static assert(!isFunctionOver!(ceil, double, double));

    static assert(!isFunctionOver!(i));
    static assert(!isFunctionOver!(i, int));
}

unittest {
    struct S {}
    static assert(isFunctionOver!((ref s) => s, S));
}

unittest {
    import std.algorithm: move;
    struct S { @disable this(); @disable void opAssign(S); @disable this(this); }
    static assert(isFunctionOver!((ref s) => s.move, S));
}


/**
    Returns true if the first argument is a unary function over the next parameter argument

    Parameter arguments can be any compile time entity that can be typed. And the first argument can be a string
    that is also accpeted by `std.functional.binaryFun` in Phobos
*/
template isUnaryOver(T...) {
    import std.functional: unaryFun;
    enum isUnaryOver = T.length == 2 && (isFunctionOver!T || is(typeof(unaryFun!(T[0])(T[1].init))));
}

///
unittest {
    void f0() {}
    void f1(int a) {}
    void f2(int a, int b) {}

    static assert(!isUnaryOver!(null, int));
    static assert( isUnaryOver!((a => a), int));
    static assert(!isUnaryOver!((a, b) => a + b, int));

    static assert(!isUnaryOver!(f0, int));
    static assert( isUnaryOver!(f1, int));
    static assert(!isUnaryOver!(f2, int));

    static assert( isUnaryOver!(f1, 3));
    static assert(!isUnaryOver!(f1, "ff"));
    static assert(!isUnaryOver!(f1, 3, 4));
    static assert( isUnaryOver!(typeof(f1), 3));
    static assert(!isUnaryOver!(typeof(f1), "ff"));
}

/**
    Returns true if the first argument is a binary function over the next one OR two parameter arguments

    If one parameter is provided then it's duplicated.

    Parameter arguments can be any compile time entity that can be typed. And the first argument can be a string
    that is also accpeted by `std.functional.binaryFun` in Phobos
*/
template isBinaryOver(T...) {
    import std.functional: binaryFun;
    static if (T.length == 2) {
        enum isBinaryOver = isBinaryOver!(T[0], T[1], T[1]);
    } else {
        enum isBinaryOver = T.length == 3 && (isFunctionOver!T || is(typeof(binaryFun!(T[0])(T[1].init, T[2].init))));
    }
}

///
unittest {
    void f0() {}
    void f1(int a) {}
    void f2(int a, int b) {}

    static assert(!isBinaryOver!(null, int));
    static assert(!isBinaryOver!((a => a), int));
    static assert( isBinaryOver!((a, b) => a + b, int));
    static assert( isBinaryOver!((a, b) => a + b, int, int));

    static assert(!isBinaryOver!(f0, int));
    static assert(!isBinaryOver!(f1, int));
    static assert( isBinaryOver!(f2, int));
    static assert( isBinaryOver!(f2, int, int));
    static assert(!isBinaryOver!(f2, int, string));
    static assert(!isBinaryOver!(f2, int, int, int));

    static assert( isBinaryOver!(f2, 3));
    static assert( isBinaryOver!(f2, 3, 3));
    static assert( isBinaryOver!(f2, 3, int));
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
    Tells you if a symbol is an @property
*/
template isProperty(alias sym) {
    import std.traits: isFunction;
    import std.algorithm: canFind;
    static if (isFunction!sym) {
        enum isProperty = [__traits(getFunctionAttributes, sym)].canFind("@property");
    } else {
        enum isProperty = false;
    }
}

///
unittest {
    int i;
    @property void f() {}

    struct S {
        int i;
        @property void f(int i) {}
    }

    static assert(!isProperty!(i));
    static assert( isProperty!(f));
    static assert(!isProperty!(S.i));
    static assert( isProperty!(S.f));
}

/**
    Tells you if a name is a member and property in a type
*/
template hasProperty(T, string name) {
    import std.meta: anySatisfy;
    import std.traits: hasMember, isFunction;

    alias ResolvedType = ResolvePointer!T;

    static if (hasMember!(ResolvedType, name) && isFunction!(__traits(getMember, ResolvedType, name))) {
        enum hasProperty = anySatisfy!(isProperty, __traits(getOverloads, ResolvedType, name));
    } else {
        enum hasProperty = false;
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

unittest {
    struct S {
        int m;
        static int sm;
        void f() {}
        static void sf() {}
        @property int rp() { return m; }
        @property void wp(int) {}
    }

    static assert(!hasProperty!(S*, "na"));
    static assert(!hasProperty!(S*, "m"));
    static assert(!hasProperty!(S*, "sm"));
    static assert(!hasProperty!(S*, "f"));
    static assert(!hasProperty!(S*, "sf"));
    static assert( hasProperty!(S*, "rp"));
    static assert( hasProperty!(S*, "wp"));
}

/**
    Represents the semantics supported by an @property member
*/
enum PropertySemantics {
    /// is a read property
    r,
    /// is a write property
    w,
    /// is a read-write property
    rw
}

/**
    Tells you what property semantics a symbol has

    Returns:
        The `PropertySemantics` of the symbol
*/
template propertySemantics(alias sym) if (isProperty!sym) {
    import std.array: split;
    import std.meta: anySatisfy;
    import std.traits: fullyQualifiedName, Parameters;

    private string lastPart(string str) {
        return str.split(".")[$ - 1];
    }

    private static immutable name = fullyQualifiedName!sym.lastPart;

    static if (is(__traits(parent, sym) T)) {
        // Parent is a type, i.e. not a module
        private alias overloads = __traits(getOverloads, T, name);
    } else {
        // Parent is a module
        private alias overloads = __traits(getOverloads, __traits(parent, sym), name);
    }

    private enum isRead(alias s) = Parameters!s.length == 0;
    private enum isWrite(alias s) = Parameters!s.length > 0;

    private enum canRead = anySatisfy!(isRead, overloads);
    private enum canWrite = anySatisfy!(isWrite, overloads);

    static if (canWrite && canRead) {
        enum propertySemantics = PropertySemantics.rw;
    } else static if (canWrite) {
        enum propertySemantics = PropertySemantics.w;
    } else {
        enum propertySemantics = PropertySemantics.r;
    }
}

version (unittest) {
    private @property int localRead() {return 9;}
    private @property void localWrite(int i, int g) {}
    private @property int localReadWrite() {return 9;}
    private @property void localReadWrite(int i) {}
}

///
unittest {
    static assert(propertySemantics!localRead == PropertySemantics.r);
    static assert(propertySemantics!localWrite == PropertySemantics.w);
    static assert(propertySemantics!localReadWrite == PropertySemantics.rw);

    struct S {
        int m;
        @property int rp() { return m; }
        @property void wp(int) {}
        @property int rwp() { return m; }
        @property void rwp(int) {}
    }

    static assert(!__traits(compiles, propertySemantics!(S.na)));
    static assert(!__traits(compiles, propertySemantics!(S.m)));
    static assert(propertySemantics!(S.rp) == PropertySemantics.r);
    static assert(propertySemantics!(S.wp) == PropertySemantics.w);
    static assert(propertySemantics!(S.rwp) == PropertySemantics.rw);
}

/**
    Lists the various protection levels that can be applied on types
*/
enum ProtectionLevel : string {
    public_ = "public",
    protected_ = "protected",
    private_ = "private",
}

/**
    Check if the access level of any symbol
*/
template protectionLevel(T...) if (T.length == 1) {
    enum protectionLevel = cast(ProtectionLevel)__traits(getProtection, T[0]);
}

version (unittest) {
    protected immutable int protectedImmutableInt = 7;
}

///
unittest {
    import std.meta: AliasSeq;

    static assert(protectionLevel!protectedImmutableInt == ProtectionLevel.protected_);

    struct S {
        int i;
        public int m0;
        protected int m1;
        private int m2;
    }

    static assert(protectionLevel!(S.i) == ProtectionLevel.public_);
    static assert(protectionLevel!(S.m0) == ProtectionLevel.public_);
    static assert(protectionLevel!(S.m0) != ProtectionLevel.protected_);
    static assert(protectionLevel!(S.m1) == ProtectionLevel.protected_);
    static assert(protectionLevel!(S.m1) != ProtectionLevel.public_);
    static assert(protectionLevel!(S.m2) == ProtectionLevel.private_);
    static assert(protectionLevel!(S.m2) != ProtectionLevel.public_);
}

/**
    Returns true if the argument is a manifest constant, built-in type field, or immutable static
*/
template isManifestAssignable(x...) if (x.length == 1) {
    enum isManifestAssignable = __traits(compiles, { enum y = x[0]; } );
}

///
unittest {
    struct A {
        int m;
        static immutable int sim = 1;
        enum e = 1;
    }

    static assert(!isManifestAssignable!(A.m));
    static assert( isManifestAssignable!(A.e));
    static assert( isManifestAssignable!(A.sim));
    static assert(!isManifestAssignable!int);
}

/**
    Checks if the resolved type of one thing is the same as the resolved type of another thing.

    If the type is callable, then `std.traits.ReturnType` is the resolved type
*/
template isOf(ab...) if (ab.length == 2) {
    alias Ts = from.bolts.meta.TypesOf!ab;
    template resolve(T) {
        import std.traits: isCallable, ReturnType;
        static if (isCallable!T) {
            alias resolve = ReturnType!T;
        } else {
            alias resolve = T;
        }
    }

    enum isOf = is(resolve!(Ts[0]) == resolve!(Ts[1]));
}

///
unittest {
    static assert( isOf!(int, 3));
    static assert( isOf!(7, 3));
    static assert( isOf!(3, int));
    static assert(!isOf!(float, 3));
    static assert(!isOf!(float, string));
    static assert(!isOf!(string, 3));

    string tostr() { return ""; }
    static assert( isOf!(string, tostr));
}

/// True if a is of type null
template isNullType(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
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

deprecated("use isNullSettable instead")
template isNullable(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
    enum isNullable = __traits(compiles, { U u = U.init; u = null; });
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

/**
    Checks if a compile time entity is a reference type.
*/
template isRefType(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
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
    Checks if an alias is a literal of some type
*/
template isLiteralOf(ab...) if (ab.length == 2) {
    enum isLiteralOf = !is(typeof(&ab[0]))
        && is(typeof(ab[0]))
        && is(typeof(ab[0]) == ab[1]);
}

///
unittest {
    static assert( isLiteralOf!("hi", string));
    static assert(!isLiteralOf!(3, string));
    static assert( isLiteralOf!(3, int));

    int a;
    static assert(!isLiteralOf!(a, int));

    void f() {}
    static assert(!isLiteralOf!(f, string));
}

/**
    Checks if an alias is a literal
*/
enum isLiteral(T...) = __traits(compiles, { enum x = T[0]; } );

///
unittest {
    int a;
    void f() {}
    assert( isLiteral!3);
    assert( isLiteral!"hi");
    assert(!isLiteral!int);
    assert(!isLiteral!a);
    assert(!isLiteral!f);
}

/**
    Checks to see if a type is copy constructable - postblit doesn't count.

    Returns false if there's a user defined postblit.
*/
template isCopyConstructable(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
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
    alias U = from.bolts.meta.TypesOf!T[0];
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
    alias U = from.bolts.meta.TypesOf!T[0];
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
    Returns true if a type has a function member
*/
template hasFunctionMember(T, string name) {
    import std.traits: hasMember;
    static if (hasMember!(T, name)) {
        import std.traits: isFunction;
        enum hasFunctionMember = isFunction!(__traits(getMember, T, name));
    } else {
        enum hasFunctionMember = false;
    }
}

///
unittest {
    static struct S {
        int i;
        void f0() {}
        int f1(int, int) { return 0; }
        static void f2(string) {}
        static int s;
    }

    static assert(!hasFunctionMember!(S, "i"));
    static assert( hasFunctionMember!(S, "f0"));
    static assert( hasFunctionMember!(S, "f1"));
    static assert( hasFunctionMember!(S, "f2"));
    static assert(!hasFunctionMember!(S, "s"));
}

/**
    Returns true if two things are equatable
*/
template areEquatable(T...) if (T.length == 2) {
    private alias ResolvedTypes = from.bolts.meta.TypesOf!T;
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
    Returns true of T can be set to null
*/
template isNullSettable(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
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
    Returns true of T can be check with null using an is statement
*/
template isNullTestable(T...) if (T.length == 1) {
    alias U = from.bolts.meta.TypesOf!T[0];
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

/**
    True if it's a ref decleration. This applies to parameters and functions
*/
template isRefDecl(T...) if (T.length == 1) {
    import std.traits: isFunction;
    import std.algorithm: canFind;
    static if (isFunction!T) {
        enum isRefDecl = [__traits(getFunctionAttributes, T[0])].canFind("ref");
    } else {
        enum isRefDecl = __traits(isRef, T[0]);
    }
}

///
unittest {
    bool checkRefParam()(auto ref int i) {
        return isRefDecl!i;
    }

    bool checkRefReturn() {
        ref int f(ref int i) {
            return i;
        }
        return isRefDecl!f;
    }

    bool checkMemberFunciton() {
        static struct S {
            int i;
            ref int value() { return i; }
        }
        S s;
        return isRefDecl!(s.value) && isRefDecl!(S.value);
    }

    int i;
    assert(        checkRefParam(i));
    static assert(!checkRefParam(3));
    static assert( checkRefReturn());
    static assert( checkMemberFunciton());
    static assert(!isRefDecl!int);
    static assert(!isRefDecl!i);
}
