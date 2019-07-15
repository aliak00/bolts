/**
    Provides meta utilities that can modify types
*/
module bolts.meta;

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

/**
    Flattens a list of types to their `ElementType` or in the case of an AliasPack it's `.UnpackDeep`

    If a type is a range then its `ElementType` is used
*/
template Flatten(Values...) {
    import std.meta: AliasSeq;
    static if (Values.length) {
        import std.range: isInputRange;
        import std.traits: isInstanceOf;

        alias Head = Values[0];
        alias Tail = Values[1..$];

        static if (isInstanceOf!(AliasPack, Head)) {
            alias Flatten = Flatten!(Head.UnpackDeep, Flatten!Tail);
        } else static if (isInputRange!Head) {
            import std.range: ElementType;
            alias Flatten = Flatten!(ElementType!Head, Flatten!Tail);
        } else {
            alias Flatten = AliasSeq!(Head, Flatten!Tail);
        }
    } else {
        alias Flatten = AliasSeq!();
    }
}

///
unittest {
    import std.algorithm: filter;
    import std.meta: AliasSeq;

    alias R1 = typeof([1, 2, 3].filter!"true");
    alias R2 = typeof([1.0, 2.0, 3.0]);

    static assert(is(Flatten!(int, double) == AliasSeq!(int, double)));
    static assert(is(Flatten!(int, R1, R2) == AliasSeq!(int, int, double)));
    static assert(is(Flatten!(R1, int) == AliasSeq!(int, int)));

    import std.traits: CommonType;
    static assert(is(CommonType!(Flatten!(int, R1, R2, float)) == double));

    static assert(is(Flatten!(R1, int, AliasPack!(AliasPack!(float, int)), int) == AliasSeq!(int, int, float, int, int)));
}

/**
    Same as an AliasSeq that does not auto expand.

    You can get to the provided compile time sequence (AliasSeq) by accessing the `.Unpack` member.
    And if you want a recursive expansion there's `UnpackDeep` for that. Also a convenience
    `.equals!(otherAliasPack)` is provided.

    See_Also:
        - https://forum.dlang.org/post/mnobngrzdmqbxomulpts@forum.dlang.org
*/
template AliasPack(T...) {
    alias Unpack = T;
    enum length = Unpack.length;

    private template UnpackDeepImpl(U...) {
        import std.meta: AliasSeq;
        static if (U.length) {
            import std.traits: isInstanceOf;
            static if (isInstanceOf!(AliasPack, U[0])) {
                alias Head = UnpackDeepImpl!(U[0].Unpack);
            } else {
                import std.meta: Alias;
                alias Head = Alias!(U[0]);
            }
            alias UnpackDeepImpl = AliasSeq!(Head, UnpackDeepImpl!(U[1 .. $]));
        } else {
            alias UnpackDeepImpl = AliasSeq!();
        }
    }

    alias UnpackDeep = UnpackDeepImpl!T;

    template equals(U...) {
        static if (T.length == U.length) {
            static if (T.length == 0) {
                enum equals = true;
            } else {
                import bolts.traits: isSame;
                enum equals = isSame!(T[0], U[0]) && AliasPack!(T[1 .. $]).equals!(U[1 .. $]);
            }
        } else {
            enum equals = false;
        }
    }

    static if (length > 0) {
        import std.meta: Alias;
        alias Head = Alias!(T[0]);
    } else {
        alias Head = void;
    }

    static if (length > 1) {
        alias Tail = AliasPack!(T[1 .. $]);
    } else {
        alias Tail = AliasPack!();
    }
}

///
unittest {
    alias P = AliasPack!(1, int, "abc");
    static assert( P.equals!(1, int, "abc"));
    static assert(!P.equals!(1, int, "cba"));

    static assert(P.Head == 1);
    static assert(P.Tail.equals!(int, "abc"));
    static assert(is(P.Tail.Head == int));
    static assert(P.Tail.Tail.Head == "abc");

    alias PackOfPacks = AliasPack!(AliasPack!(1, int), AliasPack!(2, float), 17);
    static assert(AliasPack!(PackOfPacks.UnpackDeep).equals!(1, int, 2, float, 17));
}

/**
    Zips sequences of `AliasPack`s together into an AliasPack of AliasPacks.

    See_Also:
        - https://forum.dlang.org/post/mnobngrzdmqbxomulpts@forum.dlang.org
*/
template staticZip(Seqs...) {
    import std.traits: isInstanceOf;
    import std.meta: allSatisfy, staticMap;

    private enum isPack(alias T) = isInstanceOf!(AliasPack, T);

    static assert(
        Seqs.length >= 2 && allSatisfy!(isPack, Seqs),
        "Must have 2 or more arguments of type AliasPack"
    );

    enum len = Seqs[0].length;
    static foreach (Seq; Seqs[1 .. $]) {
        static assert(
            Seq.length == len,
            "All arguments to staticZip must have the same length"
        );
    }

    alias Head(alias P) = P.Head;
    alias Tail(alias P) = P.Tail;

    static if (len == 0) {
        alias staticZip = AliasPack!();
    } else {
        alias staticZip = AliasPack!(
            AliasPack!(staticMap!(Head, Seqs)),
            staticZip!(staticMap!(Tail, Seqs)).Unpack
        );
    }
}

///
unittest {
    alias a = AliasPack!(1, 2, 3);
    alias b = AliasPack!(4, 5, 6);
    alias c = AliasPack!(7, 8, 9);
    alias d = staticZip!(a, b, c);

    static assert(d.length == 3);

    static assert(d.Unpack[0].equals!(1, 4, 7));
    static assert(d.Unpack[1].equals!(2, 5, 8));
    static assert(d.Unpack[2].equals!(3, 6, 9));
}

/**
    Filters all the members of a type based on a provided predicate

    The predicate takes two parameters - the first is the type, the second is
    the string name of the member being iterated on.
*/
template FilterMembersOf(T, alias Fn) {
    import std.meta: Filter, ApplyLeft;
    alias ResolvedType = ResolvePointer!T;
    alias FilterMembersOf = Filter!(ApplyLeft!(Fn, ResolvedType), __traits(allMembers, ResolvedType));
}

///
unittest {
    import std.meta: AliasSeq;

    struct S {
        int i;
        float f;
        int i2;
        short s;
    }

    enum hasInt(T, string name) = is(typeof(__traits(getMember, T, name)) == int);
    static assert(FilterMembersOf!(S, hasInt) == AliasSeq!("i", "i2"));
}
