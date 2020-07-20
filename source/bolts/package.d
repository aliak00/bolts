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

    Signatures_(experimental):

    Signatures are a way to enforce types to comply with other types. For example if you are making a range you can ensure your types conform to a range by mixing in a `Models` template to the type that needs it. You can also use the utilities provided here to constrain functions to types that adhere to a specific signature.

    ---
    interface InputRange(T) {
        @property bool empty();
        @property T front();
        @ignoreAttributes void popFront();
    }

    struct MyRange {
        mixin Models!(InputRange!int);
    }
    ---

    The above will fail to compile with something like:

    ---
    source/bolts/experimental/signatures.d(310,5): Error: static assert:  "Type MyRange does not comply to signature InputRange!(int)
      Missing identifier empty of type bool.
      Missing identifier front of type int.
      Missing identifier popFront of function void().
      source/bolts/experimental/signatures.d(464): <-- Signature InputRange!(int) defined here.
      source/bolts/experimental/signatures.d(471): <-- Checked here."
    ---

    Refraction_(experimental):

    It is sometimes necessary to create a function which is an exact copy of
    another function. Or sometimes it is necessary to introduce a few variations,
    while carrying all the other aspects. Because of function attributes, parameter
    storage classes and user-defined attributes, this requires building a string
    mixin. In addition, the mixed-in code must refer only to local names, if it is
    to work across module boundaires. This module facilitates the creation of such
    mixins.

    For example, this creates a function that has a different name and return type,
    but retains the 'pure' attribute from the original function:

    ---
    pure int answer() { return 42; }
    mixin(
      refract!(answer, "answer").withName("realAnswer")
      .withReturnType("real")
      .mixture);
    static assert(is(typeof(realAnswer()) == real));
    static assert(functionAttributes!realAnswer & FunctionAttribute.pure_);
    ---


All_the_things:

$(TABLE
$(TR $(TH Module) $(TH Function) $(TH Description))
$(TR
    $(TD `bolts.from`)
    $(TD $(DDOX_NAMED_REF bolts.from.from, `from`))
    $(TD lazy import of symbols)
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
    $(TD $(DDOX_NAMED_REF bolts.meta.Zip, `Zip`))
    $(TD Zip m n-tuple `AliasPack`s together to form n m-tuple AliasPacks)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.Pluck, `Pluck`))
    $(TD Extract `AliasPack` elements at positions)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.FilterMembersOf, `FilterMembersOf`))
    $(TD Filters the members of a type based on a has-predicate)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.meta.RemoveAttributes, `RemoveAttributes`))
    $(TD Removes all the attributes of a symbol and returns the new type)
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
    $(TD Allows you to query a type or alias with a nicer syntax, i.e. `isNullSettable!T` == `iz!T.nullSettable`)
    )
$(TR
    $(TD `bolts.experimental.signatures`)
    $(TD $(DDOX_NAMED_REF bolts.experimental.signatures.isModelOf, `isModelOf`))
    $(TD Allows you to check if a structure models another structure - i.e. enforces duck typing)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.experimental.signatures.Models, `Models`))
    $(TD Mixin that throws a compile error if a structure does not match another)
    )
$(TR
    $(TD `bolts.experimental.refraction`)
    $(TD $(DDOX_NAMED_REF bolts.experimental.refraction.refract, `refract`))
    $(TD Returns a compile time object that helps create a string mixin corresponding to a function, possibly with variations)
    )
$(TR
    $(TD `bolts.traits`)
    $(TD $(DDOX_NAMED_REF bolts.traits.functions.isFunctionOver, `isFunctionOver`))
    $(TD Checks if a function is n-ary over the passed in types)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.functions.isUnaryOver, `isUnaryOver`))
    $(TD Checks if a function is unary over some type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.functions.isBinaryOver, `isBinaryOver`))
    $(TD Checks if a function is binary over some types)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.TypesOf, `TypesOf`))
    $(TD Returns an AliasSeq of the types of all values given - values can be types or expressions)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.areCombinable, `areCombinable`))
    $(TD Checks if a set of ranges and non ranges share a common type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isProperty, `isProperty`))
    $(TD Tells you if a symbol is an @property)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.has.hasProperty, `hasProperty`))
    $(TD Tells you if a name is a member and property in a type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.propertySemantics, `propertySemantics`))
    $(TD Tells you if a property symbol has read and/or write semantics)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.protectionLevel, `protectionLevel`))
    $(TD Returns the protection level for a symbol)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isManifestAssignable, `isManifestAssignable`))
    $(TD If a member of a type can be assigned to a manifest constant)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isOf, `isOf`))
    $(TD Is the resolved type is of another resolved type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isNullType, `isNullType`))
    $(TD If T is typeof(null))
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.StringOf, `StringOf`))
    $(TD Stringifies a type, unlike `.stringof` this version doesn't spit out mangled gibberish)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isSame, `isSame`))
    $(TD Returns true if a and b are the same thing - same type, same literal value, or same symbol)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isRefType, `isRefType`))
    $(TD Checks if a compile time entity is a reference type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isLiteralOf, `isLiteralOf`))
    $(TD Checks if a compile time entity is a litera of a specific type)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isLiteral, `isLiteral`))
    $(TD Checks if a compile time entity is a literal)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isCopyConstructable, `isCopyConstructable`))
    $(TD Checks if a compile time entity is copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isNonTriviallyCopyConstructable, `isNonTriviallyCopyConstructable`))
    $(TD Checks if a compile time entity is non-trivially (i.e. user defined) copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isTriviallyCopyConstructable, `isTriviallyCopyConstructable`))
    $(TD Checks if a compile time entity is trivially copy constructable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.has.hasFunctionMember, `hasFunctionMember`))
    $(TD Checks if a type has a member that is a function)
    )
 $(TR
     $(TD)
     $(TD $(DDOX_NAMED_REF bolts.traits.types.isValueType, `isValueType`))
     $(TD Checks if a compile time entity is a value type)
     )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.areEquatable, `areEquatable`))
    $(TD Returns true if two things are equatable)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isNullSettable, `isNullSettable`))
    $(TD Check if a thing can be set to null)
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.types.isNullTestable, `isNullTestable`))
    $(TD Check if a thing can be checked to be null - i.e. if (thing is null) )
    )
$(TR
    $(TD)
    $(TD $(DDOX_NAMED_REF bolts.traits.symbols.isRefDecl, `isRefDecl`))
    $(TD See if a thing is declared as ref, or function returns by ref)
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
    import bolts.experimental;
}
