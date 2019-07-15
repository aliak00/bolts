/**
    Provides compile time utilities that can query a type's members
*/
module bolts.members;

import bolts.internal;

private template AliasesOf(T, membersTuple...) {
    import std.meta: Alias, staticMap, ApplyLeft;
    alias getMember(T, string name) = Alias!(__traits(getMember, T, name));
    alias mapMembers(T, names...) = staticMap!(ApplyLeft!(getMember, T), names);
    alias AliasesOf = mapMembers!(T, membersTuple);
}

/**
    Returns a list of member functions of T

    You can retireve them as a tuple of aliases, or strings
*/
template memberFunctionsOf(T) {
    import bolts.traits: hasFunctionMember;
    import bolts.meta: FilterMembersOf;

    /// Get as tuple of strings
    alias asStrings = FilterMembersOf!(T, hasFunctionMember);

    /// Get as a tuple of aliases
    alias asAliases = AliasesOf!(T, memberFunctionsOf!T.asStrings);
}

///
unittest {
    import std.meta: AliasSeq;
    struct A {
        void opCall() {}
        void g() {}
    }

    struct B {
        int m;
        A a;
        alias a this;
        void f0() {}
        void f1() {}
    }

    immutable array = [memberFunctionsOf!B.asStrings];
    alias strings = memberFunctionsOf!B.asStrings;
    alias aliases = memberFunctionsOf!B.asAliases;

    static assert(array == ["f0", "f1"]);
    static assert(strings == AliasSeq!("f0", "f1"));

    static assert(is(typeof(array) == immutable string[]));
    static assert(is(typeof(strings) == AliasSeq!(string, string)));
    static assert(is(typeof(aliases) == AliasSeq!(typeof(B.f0), typeof(B.f1))));
}

/**
    Returns a list of all the static members of a type

    You can retireve them as a sequence of aliases, or strings.

    See_Also:
     - https://forum.dlang.org/post/duvxnpwnuphuxlrkjplh@forum.dlang.org
*/
template staticMembersOf(T) {
    import std.traits: hasStaticMember;
    import bolts.meta: FilterMembersOf;

    /// Get as tuple of strings
    alias asStrings = FilterMembersOf!(T, hasStaticMember);

    /// Get as a tuple of aliases
    alias asAliases = AliasesOf!(T, staticMembersOf!T.asStrings);
}

///
unittest {
    import std.meta: AliasSeq, Alias;
    import bolts.meta: TypesOf;
    struct S {
        static void s0() {}
        static int s1 = 3;
        static immutable int s2 = 3;
        enum e = 9;
        void f() {}
        int i = 3;
    }

    immutable array = [staticMembersOf!S.asStrings];
    alias strings = staticMembersOf!S.asStrings;
    alias aliases = staticMembersOf!S.asAliases;

    static assert(array == ["s0", "s1", "s2"]);
    static assert(strings == AliasSeq!("s0", "s1", "s2"));

    static assert(is(typeof(array) == immutable string[]));
    static assert(is(typeof(strings) == AliasSeq!(string, string, string)));
    static assert(is(typeof(aliases) == AliasSeq!(typeof(S.s0), typeof(S.s1), typeof(S.s2))));
}

/**
    Used to extract details about a specific member

    Available member traits:
        $(LI `exists`)
        $(LI `self`)
        $(LI `isProperty`)
        $(LI `protection`)

    Params:
        Params[0] = type or alias to instance of a type
        Params[1] = name of member

*/
template member(Params...) if (Params.length == 2) {
    private enum name = Params[1];
    private alias T = bolts.meta.TypesOf!Params[0];
    private alias ResolvedType = ResolvePointer!T;

    /**
        True if the member field exists
    */
    enum exists = __traits(hasMember, ResolvedType, name);

    /**
        Aliases to the member if it exists
    */
    static if (exists) {
        alias self = __traits(getMember, ResolvedType, name);
    } else {
        template self() {
            static assert(
                0,
                "Type '" ~ T.stringof ~ "' does not have member '" ~ name ~ "'."
            );
        }
    }

    /**
        See: `bolts.traits.protectionLevel`
    */
    static if (exists) {
        enum protection = from.bolts.traits.protectionLevel!self;
    }

    /**
        See: `bolts.traits.hasProperty`
    */
    static if (exists) {
        enum isProperty = from.bolts.traits.hasProperty!(ResolvedType, name);
    } else {
        enum isProperty = false;
    }

    /**
        See `bolts.traits.propertySemantics`
    */
    static if (exists && isProperty) {
        enum propertySemantics = from.bolts.traits.propertySemantics!self;
    }
}

///
unittest {
    import bolts.traits: ProtectionLevel, PropertySemantics;
    static struct S {
        public int publicI;
        protected int protectedI;
        private @property int readPropI() { return protectedI; }
    }

    // Check the protection level of various members
    static assert(member!(S, "publicI").protection == ProtectionLevel.public_);
    static assert(member!(S, "protectedI").protection == ProtectionLevel.protected_);
    static assert(member!(S, "readPropI").protection == ProtectionLevel.private_);

    // Check if any are properties
    static assert(!member!(S, "na").isProperty);
    static assert(!member!(S, "publicI").isProperty);
    static assert( member!(S, "readPropI").isProperty);

    // Check their semantics
    static assert(member!(S, "readPropI").propertySemantics == PropertySemantics.r);
}
