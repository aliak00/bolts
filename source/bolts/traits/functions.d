/**
    Traits that can query information about functions
*/
module bolts.traits.functions;

import bolts.internal;

/**
    Returns true if the passed in function is an n-ary function over the next n parameter arguments

    Parameter arguments can be any compile time entity that can be typed.

    Params:
        T = The first argument is the function to check, the second are the types it should be called over
*/
template isFunctionOver(T...) {
    import std.meta: staticMap, Alias;
    import std.traits: isSomeFunction, Parameters;
    import bolts.meta: AliasPack, Zip;

    alias Types = from.bolts.traits.TypesOf!T;

    static if (Types.length >= 1) {
        alias DesiredParams = AliasPack!(Types[1 .. $]);
        static if (isSomeFunction!(Types[0])) {
            alias ExpectedParams = AliasPack!(Parameters!(Types[0]));
            static if (DesiredParams.length == ExpectedParams.length) {
                static if (DesiredParams.length == 0) {
                    enum isFunctionOver = true;
                } else {
                    import std.meta: allSatisfy;
                    alias Pairs = Zip!(ExpectedParams, DesiredParams);
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
