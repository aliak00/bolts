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
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.nullable, `nullable`))
        $(TD True if the resolved type nullable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.nullType, `nullType`))
        $(TD True if the resolved type is typeof(null))
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.doth.doth.of, `of`))
        $(TD True if the resolved type is the same as another resolved type)
        )
    )
    
    See_also:
        - https://dlang.org/spec/template.html#variadic-templates
*/
template doth(Types...) if (Types.length == 1) {
    import bolts.traits: TypesOf;
    alias T = TypesOf!Types[0];

    /// See: `bolts.traits.isNullable`
    enum nullable = from!"bolts.traits".isNullable!T;

    /// See: `bolts.traits.isNullType`
    enum nullType = from!"bolts.traits".isNullType!T;

    /// True if the resolved type is the same as another resolved type
    static template of(OtherTypes...) if (OtherTypes.length == 1) {
        alias U = TypesOf!OtherTypes[0];
        enum of = is(T == U);
    }
}

///
unittest {
    int i = 3;
    int *pi = null;

    // Is alias of a type of vice versa
    static assert( doth!i.of!int);
    static assert(!doth!i.of!(int*));
    static assert( doth!int.of!i);
    static assert(!doth!int.of!pi);

    // Is this alias or type nullable?
    static assert( doth!pi.nullable);
    static assert( doth!(char*).nullable);
    static assert(!doth!i.nullable);
    static assert(!doth!int.nullable);

    // Is this alias or type a typeof(null)
    static assert(!doth!int.nullType);
    static assert( doth!null.nullType);
    static assert( doth!(typeof(null)).nullType);

    // Using std.meta algorithm with doth
    import std.meta: allSatisfy, AliasSeq;
    static assert(doth!int.of!3);
    static assert(allSatisfy!(doth!int.of, 3));
}
