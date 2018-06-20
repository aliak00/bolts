## Bolts Meta Poragmming Utility Library

[![Latest version](https://img.shields.io/dub/v/bolts.svg)](http://code.dlang.org/packages/bolts) [![Build Status](https://travis-ci.org/aliak00/bolts.svg?branch=master)](https://travis-ci.org/aliak00/bolts) [![codecov](https://codecov.io/gh/aliak00/bolts/branch/master/graph/badge.svg)](https://codecov.io/gh/aliak00/bolts) [![license](https://img.shields.io/github/license/aliak00/bolts.svg)](https://github.com/aliak00/bolts/blob/master/LICENSE)

Full API docs available [here](https://aliak00.github.io/bolts/bolts.html)

Bolts is a utility library for the D programming language that provides templates and compile time functions that are not available in D's std.traits and/or std.meta packages.

E.g.
```d
struct S {
    void f() {}
    static void sf() {}
    @property int rp() { return m; }
    @property void wp(int) {}
}

// Check if something is a property
static assert( hasProperty!(S, "rp"));

// Check if a range is sprted
static assert(!isSortedRange!S);

// Get a list of member functions
static assert(memberFunctions!S == ["f", "sf"]);

// Check properties of a member funciton
static assert(hasMember!(S, "f).withProtection!"public");

// Provides some meta capabilities as wel...

alias R1 = typeof([1, 2, 3].filter!"true");
alias R2 = typeof([1.0, 2.0, 3.0]);

static assert(is(FlattenRanges!(int, R1, R2) == AliasSeq!(int, int, double)));

static assert(is(TypesOf!("hello", 1, 2, 3.0, real) == AliasSeq!(string, int, int, double, real)));
```
