/++
This module helps building functions from other functions.

 It is sometimes necessary to create a function which is an exact copy of
 another function. Or sometimes it is necessary to introduce a few variations,
 while carrying all the other aspects. Because of function attributes,
 parameter storage classes and user-defined attributes, this requires building
 a string mixin. In addition, the mixed-in code must refer only to local names,
 if it is to work across module boundaires. This problem and its solution are
 by Adam D. Ruppe in a Tip of the Week, available here:
 https://stackoverflow.com/questions/32615733/struct-composition-with-mixin-and-templates/32621854#32621854

 This module facilitates the  creation of such mixins.

 +/

module bolts.experimental.refraction;

import std.algorithm.iteration : map;
import std.array;
import std.format;
import std.meta;
import std.range : iota;
import std.traits : functionAttributes, FunctionAttribute;

// Do not require caller module to import 'std.traits'. Instead use our own
// aliases in mixtures.
alias ReturnType = std.traits.ReturnType;
alias Parameters = std.traits.Parameters;

/**
   Return a `Function` object that captures all the aspects of `fun`, using the
   value of `localName` to represent the return and parameter types, and the
   UDAs. Set the `Function`'s `overloadIndex` property to `index`, or to -1 if
   it is not specified.

   The `localName` parameter is, in general, *not* the function name. Rather,
   it is a compile-time expression that involves only symbols that exist in the
   caller's scope, for example a function alias passed as a template
   parameter. See
   https://stackoverflow.com/questions/32615733/struct-composition-with-mixin-and-templates/32621854#32621854
   for a detailed explanation.

   Params:
   fun = a function
   localName = a string that represents `fun` in the caller's context
   overloadIndex = index of `fun` in its overload set, or -1
*/

Function refract(alias fun, string localName, int overloadIndex = -1)()
if (is(typeof(fun) == function)) {
    Function model = {
    name: __traits(identifier, fun),
    overloadIndex: overloadIndex,
    localName: localName,
    returnType: __MODULE__~".ReturnType!("~localName~")",
    parameters: refractParameterList!(fun, localName),
    udas: __traits(getAttributes, fun)
    .length.iota.map!(
        formatIndex!(
            "@(__traits(getAttributes, %s)[%%d])".format(localName))).array,
    attributes: functionAttributes!(fun),
    static_: (__traits(isStaticFunction, fun)
              && isAggregate!(__traits(parent, fun))),
    body_: ";",
    };

    return model;
 }

///
unittest {
    pure @nogc int answer(lazy string question);
    alias F = answer; // typically F is a template argument
    static assert(
        refract!(F, "F").mixture ==
        "pure @nogc @system %s.ReturnType!(F) answer(lazy %s.Parameters!(F)[0] _0);"
        .format(__MODULE__, __MODULE__));
}

///
unittest {
    import std.format;
    import std.traits : FunctionAttribute;
    import bolts.experimental.refraction;

    interface GrandTour {
        pure int foo() immutable;
        @nogc @trusted nothrow ref int foo(
            out real, return ref int, lazy int) const;
        @safe shared scope void bar(scope Object);
    }

    class Mock(Interface) : Interface {
        static foreach (member; __traits(allMembers, Interface)) {
            static foreach (fun; __traits(getOverloads, Interface, member)) {
                mixin({
                        enum Model = refract!(fun, "fun");
                        if (is(ReturnType!fun == void)) {
                            return Model.withBody("{}").mixture;
                        } else if (Model.attributes & FunctionAttribute.ref_) {
                            return Model.withBody(q{{
                                        static %s rv;
                                        return rv;
                                    }}.format(Model.returnType)).mixture;
                        } else {
                            return Model.withBody(q{{
                                        return %s.init;
                                    }}.format(Model.returnType)).mixture;
                        }
                    }());
            }
        }
    }

    GrandTour mock = new Mock!GrandTour;
    real x;
    int i, l;
    mock.foo(x, i, l++) = 1;
    assert(mock.foo(x, i, l++) == 1);
    assert(l == 0);
}

private enum True(T...) = true;

/**
   Return an array of `Function` objects, refracting the functions in `Scope`
   for which `IncludePredicate` evaluates to `true`, using the value of
   `localName` to represent `Scope`. `IncludePredicate` is optional; if not
   specified, refract all the functions. The `overloadIndex` property of each
   `Function` is set to the index of the function in its *entire* overload set
   (i.e. including the overloads that may have been excluded by
   `IncludePredicate`).

   Applying this function to a module, without specifying `IncludePredicate`,
   may severely affect compilation time, as *all* the properties of *all*
   functions in the module will be queried.

   Params:
   Scope = an aggregate or a module
   localName = a string mixin that represents `Scope`
   IncludePredicate = a template that takes an alias to a function and
                      evaluates to a compile time boolean
*/

auto functionsOf(
    alias Scope, string localName, alias IncludePredicate = True)()
if (is(Scope == module) || is(Scope == struct)
    || is(Scope == class) || is(Scope == interface) || is(Scope == union)) {
    Function[] functions;

    static foreach (member; __traits(allMembers, Scope)) {
        static foreach (
            overloadIndex, fun; __traits(getOverloads, Scope, member)) {
            static if (IncludePredicate!fun) {
                functions ~= refract!(
                    __traits(getOverloads, Scope, member)[overloadIndex],
                    `__traits(getOverloads, %s, "%s")[%d]`.format(
                        localName, member, overloadIndex),
                    overloadIndex);
            }
        }
    }

    return functions;
}

///
unittest {
    static union Answers {
        int answer();
        void answer();
        string answer();
    }

    alias Container = Answers;

    enum NotVoid(alias F) = !is(ReturnType!(F) == void);

    enum functions = functionsOf!(Container, "Container", NotVoid);

    static assert(functions.length == 2);

    static assert(
        functions[0].mixture ==
        q{@system %s.ReturnType!(__traits(getOverloads, Container, "answer")[0]) answer();}
        .format(__MODULE__));
    static assert(functions[0].overloadIndex == 0);

    static assert(
        functions[1].mixture ==
        q{@system %s.ReturnType!(__traits(getOverloads, Container, "answer")[2]) answer();}
        .format(__MODULE__));
    static assert(functions[1].overloadIndex == 2);
}

private enum isAggregate(T...) =
    is(T[0] == struct) || is(T[0] == union) || is(T[0] == class)
    || is(T[0] == interface);

private mixin template replaceAttribute(string Name) {
    alias Struct = typeof(this);
    mixin(
        "Struct copy = {",
        {
            string[] mixture;
            foreach (member; __traits(allMembers, Struct)) {
                if (__traits(getOverloads, Struct, member).length == 0) {
                    mixture ~= member ~ ":"
                        ~ (member == Name ? "value" : member);
                }
            }
            return mixture.join(",\n");
        }(),
        "};"
    );
}

unittest {
    static struct QA {
        string question;
        int answer;
        QA withQuestion(string value) {
            mixin replaceAttribute!"question";
            return copy;
        }
    }
    QA deflt = { answer: 42 };
    enum question = "How many roads must a man walk down?";
    auto result = deflt.withQuestion(question);
    assert(result.question == question);
    assert(result.answer == 42);
}

/**
   A struct capturing all the aspects of a function necessary to produce a
   string mixin that re-creates the function (excepting the body).
*/

immutable struct Function {

    /**
       A string that evaluates to a symbol representing the function in the
       local context.
    */

    string localName;

    /**
       Function name. Initial value: `__traits(identifier, fun)`.
    */

    string name;

    /**
       Return a new `Function` object with the `name` attribute set to `value`.
    */

    Function withName(string value) {
        mixin replaceAttribute!"name";
        return copy;
    }

    ///
    unittest {
        pure @nogc int answer();
        mixin(refract!(answer, "answer").withName("ultimateAnswer").mixture);
        static assert(
            __traits(getAttributes, ultimateAnswer) ==
            __traits(getAttributes, answer));
    }

    /**
       Index of function in its overload set, if created by `functionsOf`, or
       -1.
    */

    int overloadIndex;

    /**
       Return type. Initial value:
       `bolts.experimental.refraction.ReturnType!fun`.
    */

    string returnType;

    /**
       Return a new `Function` object with the `returnType` attribute set to
       `value`.
    */

    Function withReturnType(string value) {
        mixin replaceAttribute!"returnType";
        return copy;
    }

    ///
    unittest {
        pure int answer() { return 42; }
        mixin(
            refract!(answer, "answer")
            .withName("realAnswer")
            .withReturnType("real")
            .mixture);
        static assert(is(typeof(realAnswer()) == real));
        static assert(functionAttributes!realAnswer & FunctionAttribute.pure_);
    }

    /**
       Function parameters. Initial value: from the refracted function.
    */

    Parameter[] parameters;

    /**
       Return a new `Function` object with the parameters attribute set to
       `value`.
    */

    Function withParameters(immutable(Parameter)[] value) {
        mixin replaceAttribute!"parameters";
        return copy;
    }

    ///
    unittest {
        int answer();
        mixin(
            refract!(answer, "answer")
            .withName("answerQuestion")
            .withParameters(
                [ Parameter().withName("question").withType("string")])
            .mixture);
        int control(string);
        static assert(is(Parameters!answerQuestion == Parameters!control));
    }

    /**
       Return a new `Function` object with `newParameters` inserted at the
       specified `index` in the `attributes`.
    */

    Function withParametersAt(
        uint index, immutable(Parameter)[] newParameters...) {
        auto value = index == parameters.length ? parameters ~ newParameters
            : index == 0 ? newParameters ~ parameters
            : parameters[0..index] ~ newParameters ~ parameters[index..$];
        mixin replaceAttribute!"parameters";
        return copy;
    }

    /**
       Function body. Initial value: `;`.
    */

    string body_;

    /**
       Return a new `Function` object with the `body_` attribute set to
       `value`.
    */

    Function withBody(string value) {
        mixin replaceAttribute!"body_";
        return copy;
    }

    ///
    unittest {
        pure int answer();
        mixin(
            refract!(answer, "answer").withName("theAnswer")
            .withBody("{ return 42; }")
            .mixture);
        static assert(theAnswer() == 42);
    }

    /**
       Function attributes.
       Initial value: `std.traits.functionAttributes!fun`
    */

    ulong attributes;

    /**
       Return a new `Function` object with the `attributes` attribute set to
       `value`.
    */

    Function withAttributes(uint value) {
        mixin replaceAttribute!"attributes";
        return copy;
    }

    ///
    unittest {
        nothrow int answer();
        enum model = refract!(answer, "answer");
        with (FunctionAttribute) {
            mixin(
                model
                .withName("pureAnswer")
                .withAttributes(model.attributes | pure_)
                .mixture);
            static assert(functionAttributes!pureAnswer & pure_);
            static assert(functionAttributes!pureAnswer & nothrow_);
        }
    }

    /**
       If `true`, prefix generated function with `static`. Initial value:
       `true` if the refracted function is a static *member* function inside a
       struct, class, interface, or union.
    */

    bool static_;

    /**
       Return a new `Function` object with the `static_` attribute set to
       `value`.
    */

    Function withStatic(bool value) {
        mixin replaceAttribute!"static_";
        return copy;
    }

    ///
    unittest {
        struct Question {
            static int answer() { return 42; }
        }
        mixin(
            refract!(Question.answer, "Question.answer")
            .withStatic(false)
            .withBody("{ return Question.answer; }")
            .mixture);
        static assert(answer() == 42);
    }

    /**
       User defined attributes.
       Initial value:
       `bolts.experimental.refraction.ParameterAttributes!(fun, parameterIndex)...[attributeIndex...])`.
    */

    string[] udas;

    /**
       Return a new `Function` object with the `udas` attribute set to `value`.
    */

    Function withUdas(immutable(string)[] value) {
        mixin replaceAttribute!"udas";
        return copy;
    }

    ///
    unittest {
        import std.typecons : tuple;
        @(666) int answer();

        mixin(
            refract!(answer, "answer")
            .withName("answerIs42")
            .withUdas(["@(42)"])
            .mixture);
        static assert(__traits(getAttributes, answerIs42).length == 1);
        static assert(__traits(getAttributes, answerIs42)[0] == 42);
    }

    /**
       Return mixin code for this `Function`.
    */

    string mixture() {
        return join(
            udas ~
            attributeMixtureArray() ~
            [
                returnType,
                name ~ "(" ~ parameterListMixtureArray.join(", ") ~ ")",
            ], " ") ~
            body_;
    }

    string[] parameterListMixtureArray() {
        return map!(p => p.mixture)(parameters).array;
    }

    /**
       Return the argument list as an array of strings.
    */

    const(string)[] argumentMixtureArray() {
        return parameters.map!(p => p.name).array;
    }

    ///
    unittest {
        int add(int a, int b);
        static assert(
            refract!(add, "add").argumentMixtureArray == [ "_0", "_1" ]);
    }

    /**
       Return the argument list as a string.
    */

    string argumentMixture() {
        return argumentMixtureArray.join(", ");
    }

    ///
    unittest {
        int add(int a, int b);
        static assert(refract!(add, "add").argumentMixture == "_0, _1");
    }

    /**
       Return the attribute list as an array of strings.
    */

    string[] attributeMixtureArray() {
        with (FunctionAttribute) {
            return []
                ~ (static_ ? ["static"] : [])
                ~ (attributes & pure_ ? ["pure"] : [])
                ~ (attributes & nothrow_ ? ["nothrow"] : [])
                ~ (attributes & property ? ["@property"] : [])
                ~ (attributes & trusted ? ["@trusted"] : [])
                ~ (attributes & safe ? ["@safe"] : [])
                ~ (attributes & nogc ? ["@nogc"] : [])
                ~ (attributes & system ? ["@system"] : [])
                ~ (attributes & const_ ? ["const"] : [])
                ~ (attributes & immutable_ ? ["immutable"] : [])
                ~ (attributes & inout_ ? ["inout"] : [])
                ~ (attributes & shared_ ? ["shared"] : [])
                ~ (attributes & return_ ? ["return"] : [])
                ~ (attributes & scope_ ? ["scope"] : [])
                ~ (attributes & ref_ ? ["ref"] : [])
                ;
        }
    }

    ///
    unittest {
        nothrow pure int answer();
        enum model = refract!(answer, "answer");
        static assert(
            model.attributeMixtureArray == ["pure", "nothrow", "@system"]);
    }

    /**
       Return the attribute list as a string.
    */

    string attributeMixture() {
        return attributeMixtureArray.join(" ");
    }

    ///
    unittest {
        nothrow pure int answer();
        enum model = refract!(answer, "answer");
        static assert(model.attributeMixture == "pure nothrow @system");
    }
}

/**
   A struct capturing all the properties of a function parameter.
*/

immutable struct Parameter {
    /**
       Parameter name. Initial value: `_i`, where `i` is the position of the
       parameter.
    */

    string name;

    /**
       Return a new Parameter object with the `name` attribute set to `value`.
    */

    Parameter withName(string value) {
        mixin replaceAttribute!"name";
        return copy;
    }

    /**
       Parameter type. Initial value: `std.traits.Parameter!fun[i]`, where
       `fun` is the refracted function and `i` is the position of the
       parameter.
    */

    string type;

    /**
       Return a new `Parameter` object with the `type` attribute set to
       `value`.
    */

    Parameter withType(string value) {
        mixin replaceAttribute!"type";
        return copy;
    }

    /**
       Parameter storage classes. Initial value:
       `[__traits(getParameterStorageClasses, fun, i)]`, where where `fun` is
       the refracted function and `i` is the position of the parameter.
    */

    string[] storageClasses;

    /**
       Return a new `Parameter` object with the `storageClasses` attribute set
       to `value`.
    */

    Parameter withStorageClasses(immutable(string)[] value) {
        mixin replaceAttribute!"storageClasses";
        return copy;
    }

    /**
       Parameter UDAs. Initial value:
       `[@(bolts.experimental.refraction.ParameterAttribute!(fun,i)[j...])]`,
       where where `fun` is the refracted function, `i` is the position of the
       parameter, and `j...` are the positions of the UDAs.
    */

    string[] udas;

    /**
       Return a new `Parameter` object with the `udas` attribute set to
       `value`.
    */

    Parameter withUdas(immutable(string)[] value) {
        mixin replaceAttribute!"udas";
        return copy;
    }

    string mixture() {
        return join(udas ~ storageClasses ~ [ type, name ], " ");
    }
}

private Parameter refractParameter(alias Fun, string mixture, uint index)() {
    static if (is(typeof(Fun) parameters == __parameters)) {
        alias parameter = parameters[index .. index + 1];
        static if (__traits(compiles,  __traits(getAttributes, parameter))) {
            enum udaFormat = "@(%s.ParameterAttributes!(%s, %d)[%%d])".format(
                __MODULE__, mixture, index);
            enum udas = __traits(getAttributes, parameter).length.iota.map!(
                formatIndex!udaFormat).array;
        } else {
            enum udas = [];
        }

        Parameter p = {
        type: `%s.Parameters!(%s)[%d]`.format(__MODULE__, mixture, index),
            name: "_%d".format(index),
            storageClasses: [__traits(getParameterStorageClasses, Fun, index)],
            udas: udas,
        };
    }
    return p;
}

private Parameter[] refractParameterList(alias Fun, string mixture)() {
    Parameter[] result;
    static if (is(typeof(Fun) parameters == __parameters)) {
        static foreach (i; 0 .. parameters.length) {
            result ~= refractParameter!(Fun, mixture, i);
        }
    }
    return result;
}

private string formatIndex(string f)(ulong i) {
    return format!f(i);
}

/**
   Return an alias to the `j`-th user-define attribute of the `i`-th parameter
   of `fun`.

   Params:
   fun = a function
   i = zero-based index of a parameter of fun
   j = zero-based index of a user-defined attribute of i-th parameter fun
*/

template ParameterAttributes(alias fun, int i) {
    static if (is(typeof(fun) P == __parameters)) {
        alias ParameterAttributes =
            __traits(getAttributes, P[i..i+1]);
    }
}

unittest {
    struct virtual;
    void kick(int times, @virtual @("Animal") Object animal);
    static assert(ParameterAttributes!(kick, 1).length == 2);
    static assert(is(ParameterAttributes!(kick, 1)[0] == virtual));
    static assert(ParameterAttributes!(kick, 1)[1] == "Animal");

    import bolts.experimental.refraction;
    enum kickModel = refract!(kick, "kick");
    mixin(kickModel.withName("pet").mixture);
    static assert(is(typeof(pet) == typeof(kick)));

    mixin(
        kickModel
        .withName("feed")
        .withParameters(
            [ kickModel.parameters[0].withUdas(kickModel.parameters[1].udas),
              kickModel.parameters[1].withUdas(kickModel.parameters[0].udas) ])
        .mixture);
    static assert(ParameterAttributes!(feed, 0).stringof == ParameterAttributes!(kick, 1).stringof);
    static assert(ParameterAttributes!(feed, 1).stringof == ParameterAttributes!(kick, 0).stringof);
}
