/**
    Provides utilites that allow you to enforce signatures - a specification for a structure
*/
module bolts.experimental.signatures;

/**
    Checks if type `This` is a model of type `Sig`
*/
template isModelOf(This, Sig, string file = __FILE__, int line = __LINE__) {
    import bolts.traits: StringOf;
    import std.traits: hasMember, isAggregateType, isNested, OriginalType, EnumMembers;
    import std.conv: to;

    alias sigMember(string m) = __traits(getMember, Sig, m);
    alias thisMember(string m) = __traits(getMember, This, m);

    template loc(alias sym) {
        template str(string file, int line, int _) {
            enum str = file ~ "(" ~ to!string(line) ~ ")";
        }
        enum loc = str!(__traits(getLocation, sym));
    }

    string error(string str) {
        enum mixedLoc = file ~ "(" ~ to!string(line) ~ ")";
        return str
            ~ "\n  "
            ~ loc!Sig
            ~ ": <-- Signature `"
            ~ StringOf!Sig
            ~ "` defined here.\n  "
            ~ mixedLoc
            ~ ": <-- Modeled here.";
    }

    static foreach (m; __traits(allMembers, Sig)) {
        static if (is(typeof(sigMember!m))) { // Are we a typed identifier?

            // Ensure we have a member of that name
            static assert(
                hasMember!(This, m),
                "Type `" ~ StringOf!This
                    ~ "` is missing identifier named `"
                    ~ m
                    ~ "` of type `"
                    ~ StringOf!(typeof(sigMember!m))
                    ~ "`.".error
            );

            // Ensure the member is also a typed identifier
            static assert(
                is(typeof(thisMember!m)),
                "Expected type `" ~ StringOf!This
                    ~ "` to have an identifier named `"
                    ~ m
                    ~ "` but it looks like `"
                    ~ m
                    ~ "` is not an identifier.".error
            );

            // Ensure the types are the same
            static assert(
                is(typeof(sigMember!m) == typeof(thisMember!m)),
                "Expected type `" ~ StringOf!This
                    ~ "` to have identifier named `"
                    ~ m
                    ~ "` of type `"
                    ~ StringOf!(typeof(sigMember!m))
                    ~ "` but found identifier of type `"
                    ~ StringOf!(typeof(thisMember!m))
                    ~ "`.".error
            );
        } else static if (is(sigMember!m)) { // Are we a type

            // Ensure we have a member with the same name
            static assert(
                hasMember!(This, m),
                "Type `" ~ StringOf!This
                    ~ "` is missing name `"
                    ~ m
                    ~ "` of type `"
                    ~ StringOf!sigT
                    ~ "`".error
            );

            // Ensure the member is also a type
            static assert(
                is(thisMember!m),
                "Expected type `" ~ StringOf!This
                    ~ "` to have a type named `"
                    ~ m
                    ~ "` but it looks like `"
                    ~ m
                    ~ "` is not a type.".error
            );

            static if (isAggregateType!(sigMember!m)) { // If it's an aggregate type, recurse in
                static assert(isModelOf!(thisMember!m, sigMember!m, file, line));
            } else static if (is(sigMember!m == enum)) {
                static assert(
                    is(thisMember!m == enum),
                    "Expected type `" ~ StringOf!This
                        ~ "` to have enum named `"
                        ~ m
                        ~ "` but it looks like `"
                        ~ m
                        ~ "` is not an enum.".error
                );
                static assert(
                    is(OriginalType!(sigMember!m) == OriginalType!(thisMember!m)),
                    "enum not correct type",
                );
                import std.algorithm: sort, setDifference;
                static assert(
                    [__traits(allMembers, sigMember!m)] == [__traits(allMembers, thisMember!m)],
                    "Type `" ~ StringOf!This
                        ~ "` is missing the following members of enum `"
                        ~ m
                        ~ "`: "
                        ~ [__traits(allMembers, sigMember!m)]
                            .sort
                            .setDifference([__traits(allMembers, thisMember!m)].sort)
                            .to!string
                            .error
                );
            } else {
                static assert(
                    is(sigMember!m == thisMember!m),
                    "Expected type `" ~ StringOf!This
                        ~ "` to have name `"
                        ~ m
                        ~ "` of type `"
                        ~ StringOf!(sigMember!m)
                        ~ "` but found type `"
                        ~ StringOf!(thisMember!m)
                        ~ "`.".error
                );
            }
        } else {
            static assert(
                isNested!This && m == "this",
                "Don`t know member `" ~ m ~ "` of type `" ~ StringOf!This ~ "`".error
            );
        }
    }

    enum isModelOf = true;
}

///
unittest {
    struct X { int a; float z; }
    struct Y { int a; float z; }
    struct Z { int b; float z; }

    static assert(isModelOf!(Y, X));
}

/**
    Mixin that ensures a type models the desired signature of a structure
*/
mixin template ModelsSignature(alias Sig, string file = __FILE__, int line = __LINE__) {
    static assert(isModelOf!(typeof(this), Sig, file, line));
}

///
unittest {
    struct Sig {
        alias I = int;
        int x;
        float y;
        struct Inner { int a; }
        int f(int) { return 0; }
        enum X { one, two }
    }

    struct Y {
        mixin ModelsSignature!Sig;
        alias I = int;
        int x;
        float y;
        struct Inner { int a; }
        int f(int) { return 0; }
        enum X { one, two }
    }
}

unittest {
    struct TemplatedSig(T) {
        T value;
    }

    struct Y(T) {
        mixin ModelsSignature!(TemplatedSig!T);
        T value;
    }

    static assert(__traits(compiles, {
        Y!int x;
    }));
}

unittest {
    struct Sig {
        alias I = int;
        int x;
        float y;
    }

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            alias I = float;
            int x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            int I;
            int x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            alias M = int;
            int x;
            float y;
        }
    }));
}

unittest {
    struct Sig {
        alias I = int;
        int x;
        float y;
    }

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            alias I = float;
            float x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            int I;
            alias x = int;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin ModelsSignature!Sig;
            alias M = int;
            int x;
        }
    }));
}

/**
    An input range signature
*/
struct InputRange(T) {
    bool empty() { return true; }
    T front() { return T.init; }
    void popFront() {}
}

///
unittest {
    struct R(T) {
        mixin ModelsSignature!(InputRange!T);

        T[] values;
        int index;
        this(T[] arr) {
            values = arr;
        }
        bool empty() {
            return this.values.length == index;
        }
        T front() {
            return values[index];
        }
        void popFront() {
            index++;
        }
    }

    import std.range: array;
    auto r = R!int([1, 4, 2, 3]);
    assert(r.array == [1, 4, 2, 3]);
}
