/**
    The assume template takes an alias to a funciton that casts it casts it to a different
    attribute
*/
module bolts.assume;

import bolts.internal;

/**
    `assume` is a helper template that allows you to cast functions and types to make
    the compile assume they are something they are not.

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
    private auto ref assumeAttribute(FunctionAttribute assumedAttr, T)(auto ref T t) {
        enum attrs = functionAttributes!T | assumedAttr;
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
    auto ref nogc_(Args...)(auto ref Args args) {
        mixin(funcCastImpl("FunctionAttribute.nogc"));
    }
    /// calls the alias as pure with the passed in args
    auto ref pure_(Args...)(auto ref Args args) {
        mixin(funcCastImpl("FunctionAttribute.pure_"));
    }
}

///
@nogc unittest {
    static b = [1];
    auto allocates() {
        return [1];
    }
    auto a = assume!allocates.nogc_();
    assert(a == b);

    auto something(int a) {
        allocates;
    }
    assume!something.nogc_(3);
}

///
unittest {
    static int thing = 0;
    alias lambda = () => thing++;
    () pure {
        cast(void)assume!lambda.pure_();
    }();
    assert(thing == 1);
}
