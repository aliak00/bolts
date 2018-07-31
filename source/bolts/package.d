/**
    Contains a number of static reflection utilties that query types (traits) or manipulate
    types (meta).

Traits:

$(TABLE
$(TR $(TH Module) $(TH Function) $(TH Description))
$(TR
    $(TD `bolts.members`)
    $(TD $(DDOX_NAMED_REF bolts.members.memberFunctions, `memberFunctions`))
    $(TD Returns a list of all member functions)
    )
$(TR
    $(TD `bolts.members`)
    $(TD $(DDOX_NAMED_REF bolts.members.staticMembers, `staticMembers`))
    $(TD Returns a list of of all static members)
    )
$(TR
    $(TD `bolts.members`)
    $(TD $(DDOX_NAMED_REF bolts.members.hasMember, `hasMember`))
    $(TD If a type has a member with certain attributes)
    )
$(TR
    $(TD `bolts.meta`)
    $(TD $(DDOX_NAMED_REF bolts.meta.FlattenRanges, `FlattenRanges`))
    $(TD Takes a list of ranges and non ranges and returns a list of types of the ranges and types of the non ranges)
    )
$(TR
    $(TD `bolts.range`)
    $(TD $(DDOX_NAMED_REF bolts.range.isSortedRange, `isSortedRange`))
    $(TD Tells you if a range is sorted)
    )
$(TR
    $(TD `bolts.range`)
    $(TD $(DDOX_NAMED_REF bolts.range.sortingPredicate, `sortingPredicate`))
    $(TD Can be used to extract the sorting predicate for a range)
    )
$(TR
    $(TD `bolts.range`)
    $(TD $(DDOX_NAMED_REF bolts.range.CommonTypeOfRanges, `CommonTypeOfRanges`))
    $(TD Finds the common type from a list of ranges)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.TypesOf, `TypesOf`))
    $(TD Returns a list of the types of all values given - values can be types of expressions)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isKey, `isKey`))
    $(TD Traits for a type of key used in an associative array)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isUnaryOver, `isUnaryOver`))
    $(TD Checks if a function is unary over some type)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isBinaryOver, `isBinaryOver`))
    $(TD Checks if a function is binary over some types)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.areCombinable, `areCombinable`))
    $(TD Checks if a set of ranges and non ranges share a common type)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.hasProperty, `hasProperty`))
    $(TD Tells you if a name is a member and property in a type)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.propertySemantics, `propertySemantics`))
    $(TD Tells you if a property has read and/or write semantics)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isManifestAssignable, `isManifestAssignable`))
    $(TD If a member of a type can be assigned to a manifest constant)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isType, `isType`))
    $(TD If a type is of another type)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isNullType, `isNullType`))
    $(TD If T is typeof(null))
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.isNullable, `isNullable`))
    $(TD if null can be assigned to an instance of type T)
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
