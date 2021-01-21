// eslint-disable-next-line no-undef
module.exports = {
    env: {
        browser: true,
        es2021: true,
    },
    extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        ecmaVersion: 12,
        sourceType: "module",
        project: "tsconfig.json",
    },
    plugins: ["@typescript-eslint"],
    rules: {
        "@typescript-eslint/explicit-module-boundary-types": "off",
        "@typescript-eslint/no-empty-function": "off",
        "no-constant-condition": "off",
        "@typescript-eslint/no-this-alias": "off",
        "no-empty-pattern": "off",
        "prefer-const": "off",

        // "@typescript-eslint/strict-boolean-expressions": [
        //     2,
        //     { allowNullableObject: true, allowNullableBoolean: true },
        // ],

        // Stylistics
        "quote-props": ["error", "as-needed"],
        "@typescript-eslint/naming-convention": [
            "error",
            { selector: "typeLike", format: ["PascalCase"] },
            {
                selector: "typeProperty",
                format: ["UPPER_CASE", "camelCase", "snake_case"],
            },
            {
                selector: "objectLiteralProperty",
                format: ["UPPER_CASE", "camelCase", "snake_case"],
            },
            { selector: "method", format: ["camelCase"] },
            {
                selector: "property",
                format: ["camelCase"],
            },
            { selector: "parameterProperty", format: ["camelCase"] },
            {
                selector: "variableLike",
                format: ["camelCase"],
                leadingUnderscore: "allow",
            },
        ],

        // TODO enable these
        "@typescript-eslint/no-unused-vars": "off",
        "@typescript-eslint/no-explicit-any": "off",
    },
};
