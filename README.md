## Bolts Meta Programming Utility Library

[![Latest version](https://img.shields.io/dub/v/bolts.svg)](https://code.dlang.org/packages/bolts) [![Build Status](https://travis-ci.org/aliak00/bolts.svg?branch=master)](https://travis-ci.org/aliak00/bolts) [![codecov](https://codecov.io/gh/aliak00/bolts/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/bolts) [![license](https://img.shields.io/github/license/aliak00/bolts.svg)](https://github.com/aliak00/bolts/blob/master/LICENSE)

Full API docs available [here](https://aliak00.github.io/bolts/bolts.html)

Bolts is a utility library for the D programming language which contains a number of static reflection utilties that query compile time entities (traits) or transform them (meta). General utilties are in the modules `traits` and `meta`, and more specific ones are in dedicated modules (i.e. `bolts.members` provides utilities over a type's members).

## Modules:

* **meta**: has functions that result in compile time entity transofrmations, including:
    * `Flatten`, `AliasPack`, `staticZip`, `FilterMembersOf`, `RemoveAttributes`.
* **traits**: has general utitlites that can query compile time entities. including:
    * `isFunctionOver`, `isUnaryOver`, `isBinaryOver`, `isProperty`, `hasProperty`, `propertySemantics`, `areCombinable`, `isManifestAssignable`, `isOf`, `isSame`, `isNullType`, `StringOf`, `isRefType`, `isValueType`, `isLiteralOf`, `isLiteral`, `isCopyConstructable`, `isNonTriviallyCopyConstructable`, `protectionLevel`, `isTriviallyCopyConstructable`, `hasFunctionMember`, `areEquatable`, `isNullSettable`, `isNullTestable`, `isRefDecl`, `TypesOf`
* **members**: has functions that allow you to query about the members of types
    * `staticMembersOf`, `memberFunctionsOf`, `member` (not eponymous)
* **range**: query ranges
    * `isSortedRange`, `sortingPredicate`, `CommonTypeOfRanges`
* **aa**: has functions that act on associative arrays
    * `isKey` (not eponymous)
* **iz**: super non-eponymous template that provides a lot of the functionality that's in the traits module with a different sytax that allows their usage in meta functions as well.
* **experimental**: contains experimental features
    *signatures: working implementation of type signatures

Most functions here operate on any compile time entity. For example `isUnaryOver` works in both these situatons:

```d
int i;
void f(int) {}
isFunctionOver!(f, int);
isFunctionOver!(f, 3);
isFunctionOver!(f, i);
```

## Iz super template

The `iz` super template. Has a lot of the traits on types encapulated in one place. So if there's a trait that tells you something about a compile time entity, chances are `iz` will have it. E.g:

```d
void f(int, float, string) {}
iz!f.functionOver!(int, float, string);
iz!f.functionOver!(3, float, "");
```

## Member super template

The `member` super template, found in the `bolts.members` module is similar to the `iz` template but works on members of types only:

```d
import bolts.members: member;
struct S {
    static void f() {}
}
assert(member!(S, "f").exists);
assert(member!(S, "f").protection == ProtectionLevel.public_);
assert(!member!(S, "f").isProperty);
```

## Signatures (experimental):

Signatures are a way to enforce types to comply with other types. For example if you are making a range you can ensure your types conform to a range by mixing in a `Models` template to the type that needs it. You can also use the utilities provided here to constrain functions to types that adhere to a specific signature.

```d
interface InputRange(T) {
    @property bool empty();
    @property T front();
    @ignoreAttributes void popFront();
}

struct MyRange {
    mixin Models!(InputRange!int);
}
```

The above will fail to compile with something like:

```
source/bolts/experimental/signatures.d(310,5): Error: static assert:  "Type MyRange does not comply to signature InputRange!(int)
  Missing identifier empty of type bool.
  Missing identifier front of type int.
  Missing identifier popFront of function void().
  source/bolts/experimental/signatures.d(464): <-- Signature InputRange!(int) defined here.
  source/bolts/experimental/signatures.d(471): <-- Checked here."
```
