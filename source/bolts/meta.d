/**
    Provides meta utilities that can modify types
*/
module bolts.meta;

/**
    Flattens a list of ranges and non ranges.

    If a type is a range then its `ElementType` is used
*/
template FlattenRanges(Values...) {
    import std.meta: AliasSeq;
    static if (Values.length) {
        import std.range: isInputRange;
        alias Head = Values[0];
        alias Tail = Values[1..$];
        static if (isInputRange!Head) {
            import std.range: ElementType;
            alias FlattenRanges = FlattenRanges!(ElementType!Head, FlattenRanges!Tail);
        } else {
            alias FlattenRanges = AliasSeq!(Head, FlattenRanges!Tail);
        }
    } else {
        alias FlattenRanges = AliasSeq!();
    }
}

///
unittest {
    import std.algorithm: filter;
    import std.meta: AliasSeq;

    alias R1 = typeof([1, 2, 3].filter!"true");
    alias R2 = typeof([1.0, 2.0, 3.0]);

    static assert(is(FlattenRanges!(int, double) == AliasSeq!(int, double)));
    static assert(is(FlattenRanges!(int, R1, R2) == AliasSeq!(int, int, double)));

    import std.traits: CommonType;
    static assert(is(CommonType!(FlattenRanges!(int, R1, R2, float)) == double));
}

/**
    Same as an AliasSeq that does not auto expand.

    You can get to the provided compile time sequence by accessing the `.expand` member.
    And if you want a recursive expandion there's `expandDeep` for that. Also a convenience
    `.equals!(otherAliasPack)` is provided.

    SeeAlso:
        - https://forum.dlang.org/post/mnobngrzdmqbxomulpts@forum.dlang.org
*/
template AliasPack(T...) {
    import std.meta: AliasSeq, staticMap;
    import std.traits: isInstanceOf;
    import bolts.traits: isSame;;

    alias expand = T;
    enum length = expand.length;

    private template ExpandDeepImpl(U...) {
        import std.meta: AliasSeq;
        static if (U.length) {
            import std.traits: isInstanceOf;
            static if (isInstanceOf!(AliasPack, U[0])) {
                alias Head = ExpandDeepImpl!(U[0].expand);
            } else {
                import std.meta: Alias;
                alias Head = Alias!(U[0]);
            }
            alias ExpandDeepImpl = AliasSeq!(Head, ExpandDeepImpl!(U[1 .. $]));
        } else {
            alias ExpandDeepImpl = AliasSeq!();
        }
    }

    alias expandDeep = ExpandDeepImpl!T;

    template equals(U...) {
        static if (T.length == U.length) {
            static if (T.length == 0)
                enum equals = true;
            else
                enum equals = isSame!(T[0], U[0]) && AliasPack!(T[1 .. $]).equals!(U[1 .. $]);
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
    static assert(AliasPack!(PackOfPacks.expandDeep).equals!(1, int, 2, float, 17));
}

/**
    Zips sequences of `AliasPack`s together into an AliasPack of AliasPacks.

    SeeAlso:
        - https://forum.dlang.org/post/mnobngrzdmqbxomulpts@forum.dlang.org
*/
template staticZip(Seqs...) {
    import std.traits: isInstanceOf;
    import std.meta: allSatisfy, AliasSeq, staticMap;

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
            staticZip!(staticMap!(Tail, Seqs)).expand
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

    static assert(d.expand[0].equals!(1, 4, 7));
    static assert(d.expand[1].equals!(2, 5, 8));
    static assert(d.expand[2].equals!(3, 6, 9));
}
