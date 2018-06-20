/**
    Provides utilities that can return members of certain qualities
*/
module bolts.members;

import bolts.internal;

/// Returns a list of member functions of T
template memberFunctions(T) {
    // Get them as an array
    @property auto array() {
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
}

///
unittest {
    struct A {
        void opCall() {}
        void g() {}
    }

    struct B {
        int m;
        A a;
        alias a this;
        void f() {}
    }

    static assert(is(typeof(memberFunctions!B.array) == string[]));
    static assert(memberFunctions!B.array == ["f"]);
}

template staticMembers(T) {
    // https://forum.dlang.org/post/duvxnpwnuphuxlrkjplh@forum.dlang.org
    import std.meta: Filter, staticMap, Alias, AliasSeq, ApplyLeft;
    import std.traits: hasStaticMember;
    alias FilterMembers(T, alias Fn) = Filter!(ApplyLeft!(Fn, T), __traits(allMembers, T));

    /// Get as AliasSeq of strings
    alias tuple = FilterMembers!(T, hasStaticMember);

    /// Get as array of immutable strings
    immutable array = [AliasSeq!(staticMembers!T.tuple)];
}

unittest {
    import std.meta: AliasSeq;
    struct S {
        static void s0() {}
        static int s1 = 3;
        static immutable int s2 = 3;
        enum e = 9;
        void f() {}
        int i = 3;
    }

    alias t = staticMembers!S.tuple;
    alias a = staticMembers!S.array;

    static assert(t == AliasSeq!("s0", "s1", "s2"));
    static assert(a == ["s0", "s1", "s2"]);

    static assert(is(typeof(a) == immutable string[]));
    static assert(is(typeof(t) == AliasSeq!(string, string, string)));
}