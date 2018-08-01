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

    Doth_Super_Template:

    The $(DDOX_NAMED_REF bolts.doth.doth, `doth`) super template. Has a lot of the traits on types encapulated in one place. So
    if there's a trait that tells you something about a compile time entity, chances are `doth` will have it. E.g:
    ---
    void f(int, float, string) {}
    doth!f.unaryOver!(int, float, string);
    doth!f.unaryOver!(3, float, "");
    ---

All_the_things:

$(TABLE
$(TR $(TH Module) $(TH Function) $(TH Description))
$(TR
    $(TD `bolts.members`)
    $(TD $(DDOX_NAMED_REF bolts.members.memberFunctions, `memberFunctions`))
    $(TD Returns a list of all member functions)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.members.staticMembers, `staticMembers`))
    $(TD Returns a list of of all static members)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.members.hasMember, `hasMember`))
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
    $(TD $(DDOX_NAMED_REF bolts.traits.hasProperty, `hasProperty`))
    $(TD Tells you if a name is a member and property in a type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.propertySemantics, `propertySemantics`))
    $(TD Tells you if a property has read and/or write semantics)
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
    $(TD `bolts.aa`)
    $(TD $(DDOX_NAMED_REF bolts.aa.isKey, `isKey`))
    $(TD Traits for a type of key used in an associative array)
    )
$(TR
    $(TD `bolts.doth`)
    $(TD $(DDOX_NAMED_REF bolts.doth.doth, `doth`))
    $(TD Allows you to query a type or alias with a nicer syntax, i.e. `isNullable!T` == `doth!T.nullable`)
    )
)
*/
module bolts;

public {
    import bolts.traits;
    import bolts.meta;
    import bolts.range;
    import bolts.members;
}
