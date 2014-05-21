define (require, exports, module) ->
        
        exports = describe "Compiler", ->
                describe "TypeResolver", ->
                        it "resolves NewExpression", ->
                                ast = esprima.parse "var v4 = new Vec4()"
                                console.log ast
