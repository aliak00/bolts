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
