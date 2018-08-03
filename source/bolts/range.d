/**
    Static introspection utilties for ranges
*/
module bolts.range;

import bolts.internal;

/**
    True if R is a `SortedRange`

    See_Also:
        `std.range.SortedRange`
*/
template isSortedRange(R...) if (R.length == 1) {
    import std.range: SortedRange;
    import bolts.meta: TypesOf;
    alias T = TypesOf!R[0];
    enum isSortedRange = is(T : SortedRange!U, U...);
}

///
unittest {
    import std.algorithm: sort;
    import std.range: assumeSorted;
    static assert(isSortedRange!(typeof([0, 1, 2])) == false);
    static assert(isSortedRange!([0, 1, 2].sort) == true);
    static assert(isSortedRange!(typeof([0, 1, 2].assumeSorted)) == true);
    static assert(isSortedRange!int == false);
}

/**
    Given a `SortedRange` R, `sortingPredicate!R(a, b)` will call in to the predicate
    that was used to create the `SortedRange`

    Params:
        Range = the range to extract the predicate from
        fallbackPred = the sorting predicate to fallback to if `Range` is not a `SortedRange`
*/
template sortingPredicate(Args...)
if ((Args.length == 1 || Args.length == 2) && from!"std.range".isInputRange!(from!"bolts.meta".TypesOf!Args[0])) {
    import bolts.meta: TypesOf;
    import std.range: SortedRange;
    import std.functional: binaryFun;
    alias R = TypesOf!Args[0];
    static if (is(R : SortedRange!P, P...)) {
        alias sortingPredicate = binaryFun!(P[1]);
    } else {
        static if (Args.length == 2) {
            alias pred = binaryFun!(Args[1]);
        } else {
            alias pred = (a, b) => a < b;
        }
        alias sortingPredicate = pred;
    }
}

///
unittest {
    import std.algorithm: sort;

    // As a type
    assert(sortingPredicate!(typeof([1].sort!"a < b"))(1, 2) == true);
    assert(sortingPredicate!(typeof([1].sort!((a, b) => a > b)))(1, 2) == false);

    // As a value
    assert(sortingPredicate!([1].sort!"a > b")(1, 2) == false);
    assert(sortingPredicate!([1].sort!((a, b) => a < b))(1, 2) == true);

    // Default predicate
    assert(sortingPredicate!(int[])(1, 2) == true);
}

/// Finds the CommonType of a list of ranges
template CommonTypeOfRanges(Rs...) if (from!"std.meta".allSatisfy!(from!"std.range".isInputRange, Rs)) {
    import std.traits: CommonType;
    import std.meta: staticMap;
    import std.range: ElementType;
    alias CommonTypeOfRanges = CommonType!(staticMap!(ElementType, Rs));
}

///
unittest {
    auto a = [1, 2];
    auto b = [1.0, 2.0];
    static assert(is(CommonTypeOfRanges!(typeof(a), typeof(b)) == double));
}
