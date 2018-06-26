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
    static if (Values.length)
    {
        import std.range: isInputRange;
        alias Head = Values[0];
        alias Tail = Values[1..$];
        static if (isInputRange!Head)
        {
            import std.range: ElementType;
            alias FlattenRanges = FlattenRanges!(ElementType!Head, FlattenRanges!Tail);
        }
        else
        {
            alias FlattenRanges = AliasSeq!(Head, FlattenRanges!Tail);
        }
    }
    else
    {
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
    Returns the types of all values given.

    $(OD isFunction!T then the typeof the address is taken)
    $(OD If typeof(T) can be taken it is)
    $(OD Else it is appended on as is)

    Returns:
        AliasSeq of the resulting types
*/
template TypesOf(Values...) {
    import std.meta: AliasSeq;
    import std.traits: isExpressions, isFunction;
    static if (Values.length) {
        static if (isFunction!(Values[0])) {
            alias T = typeof(&Values[0]);
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
