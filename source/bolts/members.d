/**
    Provides compile time utilities that can query a type's members
*/
module bolts.members;

import bolts.internal;

private template GetMembersAsAliases(T, membersTuple...) {
    import std.meta: Alias, staticMap, ApplyLeft;
    alias getMember(T, string name) = Alias!(__traits(getMember, T, name));
    alias GetMembers(T, names...) = staticMap!(ApplyLeft!(getMember, T), names);
    alias GetMembersAsAliases = GetMembers!(T, membersTuple);
}

/// Returns a list of member functions of T
template memberFunctions(T) {
    import std.meta: aliasSeqOf;

    auto generateArray() {
        import std.traits: isFunction;
        string[] strings;
        foreach (member; __traits(allMembers, T)) {
            static if (is(typeof(mixin("T." ~ member)) F))
            {
                if (isFunction!F) {
                    strings ~= member;
                }
            }
        }
        return strings;
    }

    /// Get as array of immutable strings
    immutable array = generateArray;

    /// Get as tuple of strings
    alias tuple = aliasSeqOf!(memberFunctions!T.array);

    /// Get as a tuple of aliases
    alias aliases = GetMembersAsAliases!(T, memberFunctions!T.tuple);
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

    alias array = memberFunctions!B.array;
    alias tuple = memberFunctions!B.tuple;
    alias aliases = memberFunctions!B.aliases;

    static assert(array == ["f0", "f1"]);
    static assert(tuple == AliasSeq!("f0", "f1"));

    static assert(is(typeof(array) == immutable string[]));
    static assert(is(typeof(tuple) == AliasSeq!(immutable string, immutable string)));
    static assert(is(typeof(aliases) == AliasSeq!(typeof(B.f0), typeof(B.f1))));
}

/**
    Returns a list of all the static members of a type

    See_Also:
     - https://forum.dlang.org/post/duvxnpwnuphuxlrkjplh@forum.dlang.org
*/
template staticMembers(T) {
    import std.meta: Filter, AliasSeq, ApplyLeft;
    import std.traits: hasStaticMember;

    alias FilterMembers(U, alias Fn) = Filter!(ApplyLeft!(Fn, U), __traits(allMembers, U));

    /// Get as array of immutable strings
    immutable array = [AliasSeq!(staticMembers!T.tuple)];

    /// Get as tuple of strings
    alias tuple = FilterMembers!(T, hasStaticMember);

    /// Get as a tuple of aliases
    alias aliases = GetMembersAsAliases!(T, staticMembers!T.tuple);
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

    alias array = staticMembers!S.array;
    alias tuple = staticMembers!S.tuple;
    alias aliases = staticMembers!S.aliases;

    static assert(array == ["s0", "s1", "s2"]);
    static assert(tuple == AliasSeq!("s0", "s1", "s2"));

    static assert(is(typeof(array) == immutable string[]));
    static assert(is(typeof(tuple) == AliasSeq!(string, string, string)));
    static assert(is(typeof(aliases) == AliasSeq!(typeof(S.s0), typeof(S.s1), typeof(S.s2))));
}

/**
    Used to check if T has a member with a specific trait

    Available member traits:
        $(LI `exists`)
        $(LI `self`)
        $(LI `hasProtection(string protectionLevel`)

    Params:
        T = type to check
        name = name of field in type

*/
template member(T, string name) {
    /**
        True if the member field exists
    */
    enum exists = __traits(hasMember, T, name);

    /**
        Aliases to the member if it exists
    */
    static if (exists) {
        static if (from.std.traits.isPointer!T) {
            alias U = from.std.traits.PointerTarget!T;
        } else {
            alias U = T;
        }
        alias self = __traits(getMember, U, name);
    } else {
        template self() {
            static assert(
                0,
                "Type '" ~ T.stringof ~ "' does not have member '" ~ name ~ "'."
            );
        }
    }

    /**
        Check if the member has the required access level

        Params:
            level = protection level (public/protected/private)
    */
    template hasProtection(string level) {
        static if (exists) {
            enum hasProtection = __traits(getProtection, self) == level;
        } else {
            enum hasProtection = false;
        }
    }

    static if (exists) {
        enum isProperty = from.bolts.traits.hasProperty!(T, name);
    } else {
        enum isProperty = false;
    }
}

///
unittest {
    import std.meta: AliasSeq;

    struct SProtection {
        int i;
        public int m0;
        protected int m1;
        private int m2;
    }

    static foreach (T; AliasSeq!(SProtection, SProtection*)) {
        static assert( member!(T, "i").hasProtection!"public");
        static assert( member!(T, "m0").hasProtection!"public");
        static assert(!member!(T, "m0").hasProtection!"protected");
        static assert( member!(T, "m1").hasProtection!"protected");
        static assert(!member!(T, "m1").hasProtection!"public");
        static assert( member!(T, "m2").hasProtection!"private");
        static assert(!member!(T, "m2").hasProtection!"public");
        static assert(!member!(T, "na").hasProtection!"public");
    }
}
