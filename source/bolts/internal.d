module bolts.internal;

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}

version (unittest) {
    // Just here so can be used in unittests without importing all the time
    public import std.stdio: writeln;
}
