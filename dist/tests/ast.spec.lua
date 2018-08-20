local __ava = LibStub:GetLibrary("ava", true)
local test = __ava.test
local __AST = LibStub:GetLibrary("ovale/AST")
local OvaleASTClass = __AST.OvaleASTClass
test("parse Define", function(t)
    local ast = OvaleASTClass()
    local astNode, nodeList, annotation = ast:ParseCode("script", [[Define(test 18)]], {}, {})
    t:truthy(astNode)
    t:truthy(nodeList)
    t:truthy(annotation.definition)
    t:is(annotation.definition["test"], 18)
end)
