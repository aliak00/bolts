/**
    Contains a number of static reflection utilties that query types (traits) or manipulate
    types (meta).

Traits:

$(TABLE
$(TR $(TH Module) $(TH Function) $(TH Properties) $(TH Description))
$(TR
    $(TD `bolts.members`)
    $(TD
        $(DDOX_NAMED_REF bolts.members.memberFunctions, `memberFunctions`)
        )
    $(TD)
    $(TD Returns a list of all member functions)
    )
$(TR
    $(TD `bolts.members`)
    $(TD
        $(DDOX_NAMED_REF bolts.members.staticMembers, `staticMembers`)
        )
    $(TD)
    $(TD Returns a list of of all static members)
    )
$(TR
    $(TD `bolts.meta`)
    $(TD
        $(DDOX_NAMED_REF bolts.meta.FlattenRanges, `FlattenRanges`)
        )
    $(TD)
    $(TD Takes a list of ranges and non ranges and returns a list of types of the ranges and types of the non ranges)
    )
$(TR
    $(TD `bolts.meta`)
    $(TD
        $(DDOX_NAMED_REF bolts.meta.TypesOf, `TypesOf`)
        )
    $(TD)
    $(TD Returns a list of the types of all values given - values can be types of expressions)
    )
$(TR
    $(TD `bolts.meta`)
    $(TD
        $(DDOX_NAMED_REF bolts.meta.isType, `isType`)
        )
    $(TD)
    $(TD Meta function that can be used in algos to check if passed in argument is a certain type)
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
