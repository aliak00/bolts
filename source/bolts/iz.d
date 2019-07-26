/**
    Iz is is - reason for choosing iz is because is is a keyword
*/
module bolts.iz;

import bolts.internal;

/**
    `Iz` is a helper template that allows you to inspect a type or an alias.

    It takes a single element as an argument. The reason the template parameters is
    types as a variable arg sequence is becure if D does not allow (pre version 2.087)
    to say "I want either a type or alias over here, I don't care, I'll figure it out".
    But it does allow it when you use a $(I template sequence parameter)

    $(TABLE
    $(TR $(TH method) $(TH Description))
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.of, `of`))
        $(TD True if the resolved type is the same as another resolved type)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.sameAs, `sameAs`))
        $(TD True if T and U are the same "thing" (type, alias, literal value))
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.nullable, `nullable`))
        $(TD True if the resolved type is nullable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.nullType, `nullType`))
        $(TD True if the resolved type is typeof(null))
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.unaryOver, `unaryOver`))
        $(TD True if the resolved type a unary funtion over some other types)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.binaryOver, `binaryOver`))
        $(TD True if the resolved type a binary funtion over some other types)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.functionOver, `functionOver`))
        $(TD True if the resolved type an n-ary funtion over n types)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.refType, `refType`))
        $(TD True if the resolved type a reference type)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.valueType, `valueType`))
        $(TD True if the resolved type a value type)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.literalOf, `literalOf`))
        $(TD True if the resolved type is a literal of a type of T)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.literal, `literal`))
        $(TD True if the resolved type is a literal)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.copyConstructable, `copyConstructable`))
        $(TD True if resolved type is copy constructable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.nonTriviallyCopyConstructable, `nonTriviallyCopyConstructable`))
        $(TD True if resolved type is non-trivially copy constructable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.triviallyCopyConstructable, `triviallyCopyConstructable`))
        $(TD True if resolved is trivially copy constructable)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.equatableTo, `equatableTo`))
        $(TD True if resolved type is equatabel to other)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.nullTestable, `nullTestable`))
        $(TD True if resolved type can be checked against null)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.iz.iz.nullSettable, `nullSettable`))
        $(TD True if resolved type can be set to null)
        )
    )

    See_also:
        - https://dlang.org/spec/template.html#variadic-templates
*/
template iz(Aliases...) if (Aliases.length == 1) {
    import bolts.meta: TypesOf;

    alias ResolvedType = TypesOf!Aliases[0];

    /// See: `bolts.traits.isOf`
    static template of(Other...) if (Other.length == 1) {
        enum of = from.bolts.traits.isOf!(Aliases[0], Other[0]);
    }

    // TODO: Remove on major bump
    deprecated("use nullTestable")
    enum nullable = from.bolts.traits.isNullable!ResolvedType;

    /// See: `bolts.traits.isNullType`
    enum nullType = from.bolts.traits.isNullType!ResolvedType;

    /// See: `bolts.traits.isSame`
    static template sameAs(Other...) if (Other.length == 1) {
        enum sameAs = from.bolts.traits.isSame!(Aliases[0], Other[0]);
    }

    /// See: `bolts.traits.isFunctionOver`
    enum functionOver(U...) = from.bolts.traits.isFunctionOver!(Aliases[0], U);

    /// See: `bolts.traits.isUnaryOver`
    enum unaryOver(U...) = from.bolts.traits.isUnaryOver!(Aliases[0], U);

    /// See: `bolts.traits.isBinaryOver`
    enum binaryOver(U...) = from.bolts.traits.isBinaryOver!(Aliases[0], U);

    /// See: `bolts.traits.isRefType`
    enum refType = from.bolts.traits.isRefType!ResolvedType;

    /// See: `bolts.traits.isValueType`
    enum valueType = from.bolts.traits.isValueType!ResolvedType;

    /// See: `bolts.traits.isLiteralOf`
    enum literalOf(T) = from.bolts.traits.isLiteralOf!(Aliases[0], T);

    /// See: `bolts.traits.isLiteral`
    enum literal = from.bolts.traits.isLiteral!(Aliases[0]);

    /// See: `bolts.traits.isCopyConstructable`
    enum copyConstructable = from.bolts.traits.isCopyConstructable!ResolvedType;

    /// See: `bolts.traits.isNonTriviallyCopyConstructable`
    enum nonTriviallyCopyConstructable = from.bolts.traits.isNonTriviallyCopyConstructable!ResolvedType;

    /// See: `bolts.traits.isTriviallyCopyConstructable`
    enum triviallyCopyConstructable = from.bolts.traits.isTriviallyCopyConstructable!ResolvedType;

    /// See: `bolts.traits.areEquatable`
    static template equatableTo(Other...) if (Other.length == 1) {
        enum equatableTo = from.bolts.traits.areEquatable!(Aliases[0], Other[0]);
    }

    /// See: `bolts.traits.isNullTestable`
    enum nullTestable = from.bolts.traits.isNullTestable!Aliases;

    /// See: `bolts.traits.isNullSettable`
    enum nullSettable = from.bolts.traits.isNullSettable!Aliases;
}

///
unittest {
    int i = 3;
    int j = 4;
    int *pi = null;

    // Is it resolved to the same type as another?
    static assert( iz!i.of!int);
    static assert(!iz!i.of!(int*));
    static assert( iz!3.of!i);
    static assert(!iz!int.of!pi);

    // Is it the same as another?
    static assert( iz!i.sameAs!i);
    static assert(!iz!i.sameAs!j);
    static assert( iz!1.sameAs!1);
    static assert(!iz!1.sameAs!2);

    // Using std.meta algorithm with iz
    import std.meta: allSatisfy, AliasSeq;
    static assert(allSatisfy!(iz!int.of, 3, 4, int, i));

    /// Is it a function over
    static assert( iz!(a => a).unaryOver!int);
    static assert( iz!((a, b) => a).binaryOver!(int, int));
    static assert( iz!((a, b, c, d) => a).functionOver!(int, int, int, int));

    // Is this thing a value or reference type?
    struct SValueType {}
    class CRefType {}
    static assert( iz!SValueType.valueType);
    static assert(!iz!CRefType.valueType);
    static assert(!iz!SValueType.refType);
    static assert( iz!CRefType.refType);

    static assert( iz!"hello".literalOf!string);
    static assert(!iz!3.literalOf!string);

    // Is this thing copy constructable?
    static struct SDisabledCopyConstructor { @disable this(ref typeof(this)); }
    static assert(!iz!SDisabledCopyConstructor.copyConstructable);
    static assert( iz!int.copyConstructable);

    // Does this thing define a custom copy constructor (i.e. non-trivial copy constructor)
    static struct SCopyConstructor { this(ref typeof(this)) {} }
    static assert( iz!SCopyConstructor.nonTriviallyCopyConstructable);
    static assert(!iz!SCopyConstructor.triviallyCopyConstructable);
    static assert(!iz!int.nonTriviallyCopyConstructable);
    static assert( iz!int.triviallyCopyConstructable);

    // Can we equate these things?
    static assert( iz!int.equatableTo!3);
    static assert(!iz!3.equatableTo!string);

    // What null-semantics does the type have

    // Is it settable to null?
    static struct SNullSettable { void opAssign(int*) {} }
    static assert( iz!pi.nullSettable);
    static assert( iz!SNullSettable.nullSettable);
    static assert(!iz!i.nullSettable);

    // Is it checable with null? (i.e. if (this is null) )
    static assert( iz!pi.nullTestable);
    static assert(!iz!SNullSettable.nullTestable);
    static assert(!iz!i.nullTestable);

    // Is it typeof(null)?
    static assert(!iz!int.nullType);
    static assert( iz!null.nullType);
    static assert( iz!(typeof(null)).nullType);
}
