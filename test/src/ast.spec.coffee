define (require, exports, module) ->
        PathResolver = window.ShaderJs.Ast.PathResolver
        exports = describe "AST Utils", ->
                describe "Environment", ->
                        it "has namespace 'window.ShaderJs.Ast'", ->
                                expect(window.ShaderJs.Ast?).toBe true
                        it "has class 'Path'", ->
                                expect(window.ShaderJs.Ast.Path?).toBe true
                        it "has class 'Dispatcher'", ->
                                expect(window.ShaderJs.Ast.Dispatcher?).toBe true
                        it "has class 'Walker'", ->
                                expect(window.ShaderJs.Ast.Walker?).toBe true
                describe "PathResolver", ->
                        it "resolves path with no type constraints"
                        it "resolves path with type constraints"
                        it "resolves path with array accessor"
                        it "resolves path with array element accessor"
                describe "PathDispatcher", ->
                        it "dispatches simple map"
                        it "dispatches nested map"
                        it "dispatches with return values" 

