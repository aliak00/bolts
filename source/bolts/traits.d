/**
    Provides utilites that allow you to determine type traits
*/
module bolts.traits;

import bolts.internal;

/**
    Gives you information about keys in associative arrays
*/
template isKey(A) {
    /// Tells you if key of type B can be used in place of a key of type A
    enum SubstitutableWith(B) = __traits(compiles, { int[A] aa; aa[B.init] = 0; });
}

///
unittest {
    struct A {}
    struct B { A a; alias a this; }

    static assert( isKey!A.SubstitutableWith!B);
    static assert(!isKey!B.SubstitutableWith!A);
    static assert( isKey!int.SubstitutableWith!long);
    static assert(!isKey!int.SubstitutableWith!(float));
}

/// True if pred is a unary function over T0, false if there're more than one T
template isUnaryOver(alias pred, T...) {
    import std.functional: unaryFun;
    import std.traits: isExpressions;
    enum isUnaryOver = T.length == 1 && !isExpressions!T && is(typeof(unaryFun!pred(T.init)));
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

    static assert(!isUnaryOver!(f1, 3));
    static assert(!isUnaryOver!("a", 3));
}

/// True if pred is a binary function of (T0, T1) or (T0, T0). False if there's more than 2 Ts
template isBinaryOver(alias pred, T...) {
    import std.functional: binaryFun;
    import std.traits: isExpressions;
    import std.meta: anySatisfy;
    static if (T.length == 1) {
        enum isBinaryOver = !isUnaryOver!(pred, T) && isBinaryOver!(pred, T, T);
    } else {
        enum isBinaryOver = T.length == 2 && !anySatisfy!(isExpressions, T) && is(typeof(binaryFun!pred(T[0].init, T[1].init)));
    }
}

///
unittest {
    int v;
    void f0() {}
    void f1(int a) {}
    void f2(int a, int b) {}

    import std.traits: isExpressions;

    static assert(!isBinaryOver!("a", int));
    static assert(!isBinaryOver!("a > a", int));
    static assert( isBinaryOver!("a > b", int));
    static assert(!isBinaryOver!(null, int));
    static assert(!isBinaryOver!((a => a), int));
    static assert( isBinaryOver!((a, b) => a + b, int));

    static assert(!isBinaryOver!(v, int));
    static assert(!isBinaryOver!(f0, int));
    static assert(!isBinaryOver!(f1, int));
    static assert( isBinaryOver!(f2, int));
    static assert( isBinaryOver!(f2, int, int));
    static assert(!isBinaryOver!(f2, int, string));
    static assert(!isBinaryOver!(f2, int, int, int));

    static assert(!isBinaryOver!("a > b", 3));
    static assert(!isBinaryOver!("a > b", 3, 3));
    static assert(!isBinaryOver!("a > b", 3, int));
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
    static if (hasMember!(T, name))
    {
        return !is(typeof(__traits(getMember, T, name)) == function)
		    && __traits(getOverloads, T, name).length;
    }
    else
    {
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
    Used to check if T has a member with a specific trait

    Available member traits:
        $(LI `withProtection`)

    Params:
        T = type to check
        name = name of field in type

*/
template hasMember(T, string name) {
    enum yesMember = __traits(hasMember, T, name);
    /**
        Check if the member has the required access level
    */
    template withProtection(string level) {
        static if (yesMember && __traits(getProtection, __traits(getMember, T, name)) == level)
        {
            enum withProtection = true;
        }
        else
        {
            enum withProtection = false;
        }
    }
}

///
unittest {
    struct S {
        int i;
        public int m0;
        protected int m1;
        private int m2;
    }

    import std.meta: AliasSeq;
    static foreach (T; AliasSeq!(S, S*))
    {
        static assert( hasMember!(T, "i").withProtection!"public");
        static assert( hasMember!(T, "m0").withProtection!"public");
        static assert(!hasMember!(T, "m0").withProtection!"protected");
        static assert( hasMember!(T, "m1").withProtection!"protected");
        static assert(!hasMember!(T, "m1").withProtection!"public");
        static assert( hasMember!(T, "m2").withProtection!"private");
        static assert(!hasMember!(T, "m2").withProtection!"public");
        static assert(!hasMember!(T, "na").withProtection!"public");
    }
}
