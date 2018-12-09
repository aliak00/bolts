## Bolts Meta Programming Utility Library

[![Latest version](https://img.shields.io/dub/v/bolts.svg)](https://code.dlang.org/packages/bolts) [![Build Status](https://travis-ci.org/aliak00/bolts.svg?branch=master)](https://travis-ci.org/aliak00/bolts) [![codecov](https://codecov.io/gh/aliak00/bolts/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/bolts) [![license](https://img.shields.io/github/license/aliak00/bolts.svg)](https://github.com/aliak00/bolts/blob/master/LICENSE)

Full API docs available [here](https://aliak00.github.io/bolts/bolts.html)

Bolts is a utility library for the D programming language which contains a number of static reflection utilties that query compile time entities (traits) or transform them (meta). General utilties are in the modules `traits` and `meta`, and more specific ones are in dedicated modules (i.e. `bolts.members` provides utilities over a type's members).

## Modules:

* **meta**: has functions that result in compile time entity transofrmations, including:
    * `TypesOf`, `Flatten`, `AliasPack`, `staticZip`
* **traits**: has general utitlites that can query compile time entities. including:
    * `isFunctionOver`, `isUnaryOver`, `isBinaryOver`, `hasProperty`, `propertySemantics`, `areCombinable`, `isManifestAssignable`, `isOf`, `isSame`, `isNullType`, `isNullable`,
    `StringOf`, `isRefType`, `isValueType`, `isLiteralOf`
* **members**: has functions that allow you to query about the members of types
    * `staticMembers`, `memberFunction`, `hasMember` (not eponymous)
* **range**: query ranges
    * `isSortedRange`, `sortingPredicate`, `CommonTypeOfRanges`
* **aa**: has functions that act on associative arrays
    * `isKey` (not eponymous)
* **assume**: can alias functions to different attributed types. Useful for debugging.
    * `nogc_`, `pure_`
* **iz**: super non-eponymous template that provides a lot of the functionality that's in the traits module with a different sytax that allows their usage in meta functions as well.

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
