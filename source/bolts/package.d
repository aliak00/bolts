/**
    Contains a number of static reflection utilties that query compile time entities (traits) or transform
    them (meta). General utilties are in the modules `traits` and `meta` and most specific ones are in
    dedicated modules (i.e. `bolts.members` provides utilities over a type's members).

    Most functions here operate on any compile time entity. For example `isUnaryOver` works in both these situatons:
    ---
    int i;
    void f(int) {}
    isFunctionOver!(f, int);
    isFunctionOver!(f, 3);
    isFunctionOver!(f, i);
    ---

    Iz_Super_Template:

    The $(DDOX_NAMED_REF bolts.iz.iz, `iz`) super template. Has a lot of the traits on types encapulated in one place. So
    if there's a trait that tells you something about a compile time entity, chances are `iz` will have it. E.g:
    ---
    void f(int, float, string) {}
    iz!f.unaryOver!(int, float, string);
    iz!f.unaryOver!(3, float, "");
    ---

    Member_Super_Template:

    The $(DDOX_NAMED_REF bolts.members.member, `member`) super template, found in the `bolts.members` module is similar to
    the $(DDOX_NAMED_REF bolts.iz.iz, `iz`) template but works on members of types only:

    ---
    import bolts.members: member;
    struct S {
        static void f() {}
    }
    assert(member!(S, "f").exists);
    assert(member!(S, "f").protection == ProtectionLevel.public_);
    assert(!member!(S, "f").isProperty);
    ---

All_the_things:

$(TABLE
$(TR $(TH Module) $(TH Function) $(TH Description))
$(TR
    $(TD `bolts.from`)
    $(TD $(DDOX_NAMED_REF bolts.members.from, `from`))
    $(TD lazy import of modules)
    )
$(TR
    $(TD `bolts.members`)
    $(TD $(DDOX_NAMED_REF bolts.members.memberFunctionsOf, `memberFunctionsOf`))
    $(TD Returns a list of all member functions)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.members.staticMembersOf, `staticMembersOf`))
    $(TD Returns a list of of all static members)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.members.member, `member`))
    $(TD If a type has a member with certain attributes)
    )
$(TR
    $(TD `bolts.meta`)
    $(TD $(DDOX_NAMED_REF bolts.meta.TypesOf, `TypesOf`))
    $(TD Returns an AliasSeq of the types of all values given - values can be types or expressions)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.Flatten, `Flatten`))
    $(TD Takes a list of ranges and non ranges and returns a list of types of the ranges and types of the non ranges)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.AliasPack, `AliasPack`))
    $(TD Represents an AliasSeq that is not auto expanded)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.staticZip, `staticZip`))
    $(TD Zip m n-tuple `AliasPack`s together to form n m-tuple AliasPacks)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.FilterMembersOf, `FilterMembersOf`))
    $(TD Filters the members of a type based on a has-predicate)
    )
$(TR
    $(TD `bolts.range`)
    $(TD $(DDOX_NAMED_REF bolts.range.isSortedRange, `isSortedRange`))
    $(TD Tells you if a range is sorted)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.range.sortingPredicate, `sortingPredicate`))
    $(TD Can be used to extract the sorting predicate for a range)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.range.CommonTypeOfRanges, `CommonTypeOfRanges`))
    $(TD Finds the common type from a list of ranges)
    )
$(TR
    $(TD `bolts.iz`)
    $(TD $(DDOX_NAMED_REF bolts.iz.iz, `iz`))
    $(TD Allows you to query a type or alias with a nicer syntax, i.e. `isNullable!T` == `iz!T.nullable`)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isFunctionOver, `isFunctionOver`))
    $(TD Checks if a function is n-ary over the passed in types)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isUnaryOver, `isUnaryOver`))
    $(TD Checks if a function is unary over some type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isBinaryOver, `isBinaryOver`))
    $(TD Checks if a function is binary over some types)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.areCombinable, `areCombinable`))
    $(TD Checks if a set of ranges and non ranges share a common type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isProperty, `isProperty`))
    $(TD Tells you if a symbol is an @property)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.hasProperty, `hasProperty`))
    $(TD Tells you if a name is a member and property in a type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.propertySemantics, `propertySemantics`))
    $(TD Tells you if a property symbol has read and/or write semantics)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.protectionLevel, `protectionLevel`))
    $(TD Returns the protection level for a symbol)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isManifestAssignable, `isManifestAssignable`))
    $(TD If a member of a type can be assigned to a manifest constant)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isOf, `isOf`))
    $(TD Is the resolved type is of another resolved type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isNullType, `isNullType`))
    $(TD If T is typeof(null))
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isNullable, `isNullable`))
    $(TD if null can be assigned to an instance of type T)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.StringOf, `StringOf`))
    $(TD Stringifies a type, unlike `.stringof` this version doesn't spit out mangled gibberish)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isSame, `isSame`))
    $(TD Returns true if a and b are the same thing - same type, same literal value, or same symbol)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isRefType, `isRefType`))
    $(TD Checks if a compile time entity is a reference type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isValueType, `isValueType`))
    $(TD Checks if a compile time entity is a value type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isLiteralOf, `isLiteralOf`))
    $(TD Checks if a compile time entity is a litera of a specific type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isLiteral, `isLiteral`))
    $(TD Checks if a compile time entity is a literal)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isCopyConstructable, `isCopyConstructable`))
    $(TD Checks if a compile time entity is copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isNonTriviallyCopyConstructable, `isNonTriviallyCopyConstructable`))
    $(TD Checks if a compile time entity is non-trivially (i.e. user defined) copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.isTriviallyCopyConstructable, `isTriviallyCopyConstructable`))
    $(TD Checks if a compile time entity is trivially copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.hasFunctionMember, `hasFunctionMember`))
    $(TD Checks if a type has a member that is a function)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.areEquatable, `areEquatable`))
    $(TD Returns true if two things are equatable)
    )
)
*/
module bolts;

public {
    import bolts.traits;
    import bolts.meta;
    import bolts.range;
    import bolts.members;
    import bolts.iz;
    import bolts.from;
}
