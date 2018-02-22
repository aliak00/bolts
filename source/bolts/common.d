module common;

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
