
/**
    Provides utilites that allow you to determine type traits
*/
module bolts.traits;

///
unittest {
    class C {}
    struct S {}
    struct S1 {
        this(typeof(null)) {}
        void opAssign(typeof(null)) {}
    }

    static assert( isNullSettable!C);
    static assert(!isNullSettable!S);
    static assert( isNullSettable!S1);
    static assert( isNullSettable!(int *));
    static assert(!isNullSettable!(int));
}

public {
    import bolts.traits.functions;
    import bolts.traits.has;
    import bolts.traits.symbols;
    import bolts.traits.types;
}
