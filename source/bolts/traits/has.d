/**
    Traits that tell you if one thing has another thing
*/
module bolts.traits.has;

import bolts.internal;

/**
    Returns true if a type has a function member
*/
template hasFunctionMember(T, string name) {
    import std.traits: hasMember;
    static if (hasMember!(T, name)) {
        import std.traits: isFunction;
        enum hasFunctionMember = isFunction!(__traits(getMember, T, name));
    } else {
        enum hasFunctionMember = false;
    }
}

///
unittest {
    static struct S {
        int i;
        void f0() {}
        int f1(int, int) { return 0; }
        static void f2(string) {}
        static int s;
    }

    static assert(!hasFunctionMember!(S, "i"));
    static assert( hasFunctionMember!(S, "f0"));
    static assert( hasFunctionMember!(S, "f1"));
    static assert( hasFunctionMember!(S, "f2"));
    static assert(!hasFunctionMember!(S, "s"));
}

/**
    Tells you if a name is a member and property in a type
*/
template hasProperty(T, string name) {
    import std.meta: anySatisfy;
    import std.traits: hasMember, isFunction;
    import bolts.traits.symbols: isProperty;

    alias ResolvedType = ResolvePointer!T;

    static if (hasMember!(ResolvedType, name) && isFunction!(__traits(getMember, ResolvedType, name))) {
        enum hasProperty = anySatisfy!(isProperty, __traits(getOverloads, ResolvedType, name));
    } else {
        enum hasProperty = false;
    }
}

///
unittest {
    struct S {
        int m;
        static int sm;
        void f() {}
        static void sf() {}
        @property int rp() { return m; }
        @property void wp(int) {}
    }

    static assert(!hasProperty!(S, "na"));
    static assert(!hasProperty!(S, "m"));
    static assert(!hasProperty!(S, "sm"));
    static assert(!hasProperty!(S, "f"));
    static assert(!hasProperty!(S, "sf"));
    static assert( hasProperty!(S, "rp"));
    static assert( hasProperty!(S, "wp"));
}

unittest {
    struct S {
        int m;
        static int sm;
        void f() {}
        static void sf() {}
        @property int rp() { return m; }
        @property void wp(int) {}
    }

    static assert(!hasProperty!(S*, "na"));
    static assert(!hasProperty!(S*, "m"));
    static assert(!hasProperty!(S*, "sm"));
    static assert(!hasProperty!(S*, "f"));
    static assert(!hasProperty!(S*, "sf"));
    static assert( hasProperty!(S*, "rp"));
    static assert( hasProperty!(S*, "wp"));
}

