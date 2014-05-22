define (require, exports, module) ->
        TypeResolver = window.ShaderJs.TypeResolver
        
        strip = (program) ->
                return program.body[0]
                
        exports = describe "Compiler", ->
                describe "TypeResolver", ->
                        it "resolves NewExpression", ->
                                ast = strip esprima.parse "var v4 = new Vec4()"
                                symbol = ast.declarations[0]
                                symbol.scope = "test"
                                resolver = new TypeResolver()
                                resolver.resolve symbol
                                expect(symbol.value_type).toEqual "Vec4"
                                console.log resolver.type_table
                        it "resolves build-in factory function"
                        it "evaluates binary expression"
                                
