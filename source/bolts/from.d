module bolts.from;

/**
    Encompases the from import idiom in an opDispatch version

    Since:
        - 0.12.0

    See_Also:
        <li> https://dlang.org/blog/2017/02/13/a-new-import-idiom/
        <li> https://forum.dlang.org/thread/gdipbdsoqdywuabnpzpe@forum.dlang.org
*/
enum from = FromImpl!null();

///
unittest {
    // Call a function
    auto _0 = from.std.algorithm.map!"a"([1, 2, 3]);
    // Assign an object
    auto _1 = from.std.datetime.stopwatch.AutoStart.yes;

    // compile-time constraints
    auto length(R)(R range) if (from.std.range.isInputRange!R) {
        return from.std.range.walkLength(range);
    }

    assert(length([1, 2]) == 2);
}

private template CanImport(string moduleName) {
    enum CanImport = __traits(compiles, { mixin("import ", moduleName, ";"); });
}

private template ModuleContainsSymbol(string moduleName, string symbolName) {
    enum ModuleContainsSymbol = CanImport!moduleName && __traits(compiles, {
        mixin("import ", moduleName, ":", symbolName, ";");
    });
}

private struct FromImpl(string moduleName) {
    template opDispatch(string symbolName) {
        static if (ModuleContainsSymbol!(moduleName, symbolName)) {
            mixin("import ", moduleName,";");
            mixin("alias opDispatch = ", symbolName, ";");
        } else {
            static if (moduleName.length == 0) {
                enum opDispatch = FromImpl!(symbolName)();
            } else {
                enum importString = moduleName ~ "." ~ symbolName;
                static assert(
                    CanImport!importString,
                    "Symbol \"" ~ symbolName ~ "\" not found in " ~ modueName
                );
                enum opDispatch = FromImpl!importString();
            }
        }
    }
}

unittest {
    static assert(!__traits(compiles, { from.std.stdio.thisFunctionDoesNotExist(42); }));
}
