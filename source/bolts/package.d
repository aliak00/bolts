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
    $(TD Returns an array of all member functions of a class or struct)
    )
$(TR
    $(TD `algorithm.compact`)
    $(TD
        $(DDOX_NAMED_REF algorithm.compact.compact, `compact`)<br>
        $(DDOX_NAMED_REF algorithm.compact.compactBy, `compactBy`)<br>
        $(DDOX_NAMED_REF algorithm.compact.compactValues, `compactValues`)<br>
        )
    $(TD)
    $(TD Creates a range or associative array with all null/predicate values removed.)
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
