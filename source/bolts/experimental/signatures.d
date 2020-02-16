/**
    Provides utilites that allow you to enforce signatures - a specification for a structure
*/
module bolts.experimental.signatures;

private enum Report {
    all,
    one,
}

private auto checkSignatureOf(alias Model, alias Sig, Report report = Report.one)() {
    import bolts.traits: StringOf;
    import std.traits: hasMember, isAggregateType, isNested, OriginalType;
    import std.conv: to;

    alias sigMember(string member) = __traits(getMember, Sig, member);
    alias modelMember(string member) = __traits(getMember, Model, member);

    string typeToString(T)() {
        import std.traits: isFunction;
        static if (is(T == struct)) {
            return "struct";
        } else static if (is(T == class)) {
            return "class";
        } else static if (is(T == union)) {
            return "union";
        } else static if (is(T == interface)) {
            return "interface";
        } else static if (is(T == enum)) {
            return "enum";
        } else static if (isFunction!T) {
            return "function";
        } else {
            return "type";
        }
    }

    string checkTypedIdentifier(string member, SigMember)() {
        static if (is(typeof(modelMember!member) ModelMember) && is(SigMember == ModelMember)) {
            return null;
        } else {
            return "Missing identifier `"
                ~ member
                ~ "` of "
                ~ typeToString!SigMember
                ~ " `"
                ~ StringOf!SigMember
                ~ "`.";
        }
    }

    string checkEnum(string member, ModelMember, SigMember)() {
        static if (is(ModelMember == enum) && is(OriginalType!SigMember == OriginalType!ModelMember)) {
            import std.algorithm: sort, setDifference;
            auto sigMembers = [__traits(allMembers, SigMember)].sort;
            auto modelMembers = [__traits(allMembers, ModelMember)].sort;
            if (sigMembers != modelMembers) {
                return "Enum `"
                    ~ member
                    ~ "` is missing members: "
                    ~ sigMembers.setDifference(modelMembers).to!string;
            }
            return null;
        } else {
            return "Missing enum named `"
                ~ member
                ~ "` of type `"
                ~ StringOf!SigMember
                ~ " with original type `"
                ~ StringOf!(OriginalType!SigMember)
                ~ "`.";
        }
    }

    string checkAlias(string member, ModelMember, SigMember)() {
        static if (!is(SigMember == ModelMember)) {
            return "Alias `"
                ~ member
                ~ "` is wrong type. Expected alias to "
                ~ typeToString!SigMember
                ~ " `"
                ~ StringOf!SigMember
                ~ "`.";
        } else {
            return null;
        }
    }

    auto checkType(string member, SigMember)() {
        static if (is(modelMember!member ModelMember)) {
            static if (member != StringOf!SigMember) {
                if (auto error = checkAlias!(member, ModelMember, SigMember)) {
                    return error;
                }
            } else static if (is(SigMember == enum)) {
                if (auto error = checkEnum!(member, ModelMember, SigMember)) {
                    return error;
                }
            } else static if (isAggregateType!SigMember) {
                if (auto error = checkSignatureOf!(ModelMember, SigMember, report)) {
                    return error;
                }
            }
            return null;
        } else {
            static if (StringOf!SigMember != member) {
                return "Missing alias named `"
                    ~ member
                    ~ "` to "
                    ~ typeToString!SigMember
                    ~ " `"
                    ~ StringOf!SigMember
                    ~ "`.";
            } else {
                return "Missing "
                    ~ typeToString!SigMember
                    ~ " named `"
                    ~ member
                    ~ "`";
            }
        }
    }

    string checkUnknown(string member)() {
        static if (isNested!Sig && member == "this") {
            return null;
        } else {
            return "Don`t know member `" ~ member ~ "` of type `" ~ StringOf!Model ~ "`";
        }
    }

    static if (report == Report.all) {
        string[] result;
    } else {
        string result;
    }

    immutable storeResult = q{
        static if (report == Report.one) {
            result = error;
            break;
        } else {
            result ~= error;
        }
    };

    foreach (member; __traits(allMembers, Sig)) {
        static if (is(typeof(sigMember!member) T)) {
            if (auto error = checkTypedIdentifier!(member, T)) {
                mixin(storeResult);
            }
        } else static if (is(sigMember!member T)) {
            if (auto error = checkType!(member, T)) {
                mixin(storeResult);
            }
        } else {
            if (auto error = checkUnknown!member) {
                mixin(storeResult);
            }
        }
    }
    return result;
}


unittest {
    struct X { alias b = int; alias c = float; enum E1 { one } void f(int) {} enum E2 { a, b } int x; float y; short z; enum e3 { a, b } }
    struct Y { alias a = int; alias c = int;                                  enum E2 { a }    int x;          int z;   enum e3 { a, b } }

    const expectedErrors = [
        "Missing alias named `b` to type `int`.",
        "Alias `c` is wrong type. Expected alias to type `float`.",
        "Missing enum named `E1`",
        "Missing identifier `f` of function `void(int)`.",
        "Enum `E2` is missing members: [\"b\"]",
        "Missing identifier `y` of type `float`.",
        "Missing identifier `z` of type `short`.",
    ];

    assert(checkSignatureOf!(Y, X, Report.all) == expectedErrors);
}

/**
    Checks if type `Model` is a model of type `Sig`
*/
template isModelOf(alias _Model, alias _Sig) {
    import bolts.meta: TypesOf;
    alias Model = TypesOf!_Model[0];
    alias Sig = TypesOf!_Sig[0];
    enum isModelOf = checkSignatureOf!(Model, Sig, Report.one) == null;
}

/**
    Asserts that the given model follows the specification of the given signature
*/
template AssertModelOf(alias _Model, alias _Sig, string file = __FILE__, int line = __LINE__) {
    import std.algorithm: map, joiner;
    import std.range: array;
    import std.conv: to;
    import bolts.traits: StringOf;
    import bolts.meta: TypesOf;

    alias Model = TypesOf!_Model[0];
    alias Sig = TypesOf!_Sig[0];

    string addLocation(string str) {
        template symLoc(alias sym) {
            template format(string file, int line, int _) {
                enum format = file ~ "(" ~ to!string(line) ~ ")";
            }
            enum symLoc = format!(__traits(getLocation, sym));
        }
        enum assertLoc = file ~ "(" ~ to!string(line) ~ ")";
        return str
            ~ "\n  "
            ~ symLoc!Sig
            ~ ": <-- Signature `"
            ~ StringOf!Sig
            ~ "` defined here.\n  "
            ~ assertLoc
            ~ ": <-- Checked here.";
    }

    immutable errors = checkSignatureOf!(Model, Sig, Report.all);
    static assert(
        errors.length == 0,
        "Type `" ~ StringOf!Model ~ "` does not comply to signature `" ~ StringOf!Sig ~ "`"
            ~ errors
                .map!(s => "\n  " ~ s)
                .joiner
                .to!string
                .addLocation
    );
    enum AssertModelOf = true;
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
mixin template Models(alias Sig, string file = __FILE__, int line = __LINE__) {
    static assert(AssertModelOf!(typeof(this), Sig, file, line));
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
        mixin Models!Sig;
        alias I = int;
        int x;
        float y;
        struct Inner { int a; }
        int f(int) { return 0; }
        enum X { one, two }
    }

    static assert(isModelOf!(Y, Sig));
}

unittest {
    struct TemplatedSig(T) {
        T value;
    }

    struct Y(T) {
        mixin Models!(TemplatedSig!T);
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
            mixin Models!Sig;
            alias I = float;
            int x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin Models!Sig;
            int I;
            int x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin Models!Sig;
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
            mixin Models!Sig;
            alias I = float;
            float x;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin Models!Sig;
            int I;
            alias x = int;
            float y;
        }
    }));

    static assert(!__traits(compiles, {
        struct X {
            mixin Models!Sig;
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
        mixin Models!(InputRange!T);

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
