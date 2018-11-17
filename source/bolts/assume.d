/**
    The assume template takes an alias to a funciton that casts it casts it to a different
    attribute
*/
module bolts.assume;

import bolts.internal;

/**
    `assume` is a helper template that allows you to cast functions and types to make
    the compiler assume they are something they are not. This can get very useful for debugging.

    They are all marked @safe as well.

    E.g. cast a non pure function to a pure function or a non-nogc function to a nogc one

    $(TABLE
    $(TR $(TH method) $(TH Description))
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.assume.assume.nogc_, `nogc_`))
        $(TD casts a function @nogc)
        )
    $(TR
        $(TD $(DDOX_NAMED_REF bolts.assume.assume.nogc_, `pure_`))
        $(TD casts a function pure)
        )
    )
*/
template assume(alias fun) {
    import std.traits: FunctionAttribute, SetFunctionAttributes, functionLinkage, functionAttributes;
    private auto ref assumeAttribute(FunctionAttribute assumedAttr, T)(return auto ref T t) @trusted {
        enum attrs = assumedAttr;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    }
    private static funcCastImpl(string attr) {
        return `
            enum call = "assumeAttribute!(`~attr~`)((ref Args args) { return fun(args); })(args)";
            ` ~ q{
            static assert(
                __traits(compiles, {
                    mixin(call ~ ";");
                }),
                "function " ~ fun.stringof ~ " is not callable with args " ~ Args.stringof
            );
            alias R = typeof(mixin(call));
            static if (is(R == void)) {
                mixin(call ~ ";");
            } else {
                mixin("return " ~ call ~ ";");
            }
        };
    }

    /// calls the alias as nogc with the passed in args
    auto ref nogc_(Args...)(auto ref Args args) @safe {
        mixin(funcCastImpl("FunctionAttribute.nogc | FunctionAttribute.safe"));
    }
    /// calls the alias as pure with the passed in args
    auto ref pure_(Args...)(auto ref Args args) @safe {
        mixin(funcCastImpl("FunctionAttribute.pure_ | FunctionAttribute.safe"));
    }
}

version (unittest) {
    private auto allocates(int i) @system {
        static struct S {}
        auto x = new S();
        return i;
    }

    private static int thing = 0;
    private immutable impureResult = 10;
    private auto impure() {
        auto x = impureResult - thing;
        return x + thing;
    }
}

///
@nogc unittest {
    assert(assume!allocates.nogc_(3) == 3);
    static assert(!__traits(compiles, { allocates(a[0]); }));
}

///
pure unittest {
    assert(assume!impure.pure_() == impureResult);
    static assert(!__traits(compiles, { impure(); }));
}

@safe @nogc unittest {
    static struct Wrapper {
        template func0() {
            auto func0() {
                return assume!allocates.nogc_(7);
            }
        }
        template func1() {
            auto func1() {
                int[] x;
                debug {
                    x = allocates(7);
                }
                return x;
            }
        }
    }
    assert(Wrapper().func0!() == 7);
    static assert(!__traits(compiles, { int x = Wrapper().func1!(); } ));
}
