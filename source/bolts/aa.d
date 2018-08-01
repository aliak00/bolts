/**
    Provides compile time utilities to query associative arrays
*/
module bolts.aa;

import bolts.internal;

/**
    Gives you information about keys in associative arrays
*/
template isKey(A) {
    /// Tells you if key of type B can be used in place of a key of type A
    enum substitutableWith(B) = __traits(compiles, { int[A] aa; aa[B.init] = 0; });
}

///
unittest {
    struct A {}
    struct B { A a; alias a this; }

    static assert( isKey!A.substitutableWith!B);
    static assert(!isKey!B.substitutableWith!A);
    static assert( isKey!int.substitutableWith!long);
    static assert(!isKey!int.substitutableWith!(float));
}
