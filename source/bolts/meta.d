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

    If a T is an expression it is resolved with `typeof` else it is just appended

    Returns:
        AliasSeq of the resulting types
*/
template TypesOf(Values...) {
    import std.meta: AliasSeq;
    import std.traits: isExpressions;
    static if (Values.length)
    {
        static if (isExpressions!(Values[0]))
            alias T = typeof(Values[0]);
        else
            alias T = Values[0];
        alias TypesOf = AliasSeq!(T, TypesOf!(Values[1..$]));
    }
    else
    {
        alias TypesOf = AliasSeq!();
    }
}

///
unittest {
    import std.meta: AliasSeq;
    static assert(is(TypesOf!("hello", 1, 2, 3.0, real) == AliasSeq!(string, int, int, double, real)));
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
}
