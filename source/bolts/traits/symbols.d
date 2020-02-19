/**
    Traits about symbols
*/
module bolts.traits.symbols;

import bolts.internal;

/**
    Returns the types of all values given.

    $(OD If isFunction!T then the typeof the address is taken if possible)
    $(OD If typeof(T) can be taken it is)
    $(OD Else it is appended on as is)

    Returns:
        AliasSeq of the resulting types
*/
template TypesOf(Symbols...) {
    import std.meta: AliasSeq;
    import std.traits: isExpressions, isFunction;
    static if (Symbols.length) {
        static if (isFunction!(Symbols[0]) && is(typeof(&Symbols[0]) F)) {
            alias T = F;
        } else static if (is(typeof(Symbols[0]))) {
            alias T = typeof(Symbols[0]);
        } else {
            alias T = Symbols[0];
        }
        alias TypesOf = AliasSeq!(T, TypesOf!(Symbols[1..$]));
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

/**
    Checks if the resolved type of one thing is the same as the resolved type of another thing.

    If the type is callable, then `std.traits.ReturnType` is the resolved type
*/
template isOf(ab...) if (ab.length == 2) {
    alias Ts = TypesOf!ab;
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
    Returns true if the argument is a manifest constant, built-in type field, or immutable static
*/
template isManifestAssignable(alias sym) {
    enum isManifestAssignable = __traits(compiles, { enum y = sym; } );
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
template protectionLevel(symbol...) if (symbol.length == 1) {
    enum protectionLevel = cast(ProtectionLevel)__traits(getProtection, symbol[0]);
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
