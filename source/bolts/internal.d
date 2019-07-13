module bolts.internal;

public import bolts.from;

version (unittest) {
    // Just here so can be used in unittests without importing all the time
    package import std.stdio: writeln;
}
