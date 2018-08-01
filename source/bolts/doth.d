/**
    Doth is doth is is - reason for choosing doth is because is is a keyword
*/
module bolts.doth;

import bolts.internal;

/**
    Doth is a helper template that allows you to inspect a type or an alias.

    It takes a single element as an argument. The reason the template parameters is
    types as a variable arg sequence is becure if D does not allow to say "I want either
    a type or alias over here, I don't care, I'll figure it out". But it does allow it
    when you use a $(I template sequence parameter)

    $(TABLE
    $(TR $(TH method) $(TH Description))
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.of, `of`))
        $(TD True if the resolved type is the same as another resolved type)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.sameAs, `sameAs`))
        $(TD True if T and U are the same "thing" (type, alias, literal value))
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.nullable, `nullable`))
        $(TD True if the resolved type is nullable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.nullType, `nullType`))
        $(TD True if the resolved type is typeof(null))
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.unaryOver, `unaryOver`))
        $(TD True if the resolved type a unary funtion over some other types)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.binaryOver, `binaryOver`))
        $(TD True if the resolved type a binary funtion over some other types)
        )
    )

    See_also:
        - https://dlang.org/spec/template.html#variadic-templates
*/
template doth(Alises...) if (Alises.length == 1) {
    import bolts.meta: TypesOf;
    alias T = TypesOf!Alises[0];

    /// True if the resolved type is the same as another resolved type
    static template of(Other...) if (Other.length == 1) {
        enum of = from!"bolts.traits".isOf!(Alises[0], Other[0]);
    }

    /// See: `bolts.traits.isNullable`
    enum nullable = from!"bolts.traits".isNullable!T;

    /// See: `bolts.traits.isNullType`
    enum nullType = from!"bolts.traits".isNullType!T;

    /// See: `bolts.traits.isSame`
    static template sameAs(Other...) if (Other.length == 1) {
        import bolts.traits: isSame;
        enum sameAs = from!"bolts.traits".isSame!(Alises[0], Other[0]);
    }

    /// See: `bolts.traits.isFunctionOver`
    static template functionOver(U...) {
        enum functionOver = from!"bolts.traits".isFunctionOver!(Alises[0], U);
    }

    /// See: `bolts.traits.isUnaryOver`
    static template unaryOver(U...) {
        enum unaryOver = from!"bolts.traits".isUnaryOver!(Alises[0], U);
    }

    /// See: `bolts.traits.isUnaryOver`
    static template binaryOver(U...) {
        enum binaryOver = from!"bolts.traits".isBinaryOver!(Alises[0], U);
    }
}

///
unittest {
    int i = 3;
    int j = 4;
    int *pi = null;

    // Is it resolved to the same type as another?
    static assert( doth!i.of!int);
    static assert(!doth!i.of!(int*));
    static assert( doth!3.of!i);
    static assert(!doth!int.of!pi);

    // Is it the same as another?
    static assert( doth!i.sameAs!i);
    static assert(!doth!i.sameAs!j);
    static assert( doth!1.sameAs!1);
    static assert(!doth!1.sameAs!2);

    // Is it nullable?
    static assert( doth!pi.nullable);
    static assert( doth!(char*).nullable);
    static assert(!doth!i.nullable);
    static assert(!doth!int.nullable);

    // Is it typeof(null)?
    static assert(!doth!int.nullType);
    static assert( doth!null.nullType);
    static assert( doth!(typeof(null)).nullType);

    // Using std.meta algorithm with doth
    import std.meta: allSatisfy, AliasSeq;
    static assert(allSatisfy!(doth!int.of, 3, 4, int, i));

    /// Is it a function over
    static assert( doth!(a => a).unaryOver!int);
    static assert( doth!((a, b) => a).binaryOver!(int, int));
    static assert( doth!((a, b, c, d) => a).functionOver!(int, int, int, int));
}
