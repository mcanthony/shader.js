define (require, exports, module) ->
        Path = window.ShaderJs.Ast.Path
        Util = require "./util"
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
                        path = new Path()
                        # make test data
                        simple_node = Util.parseOne "answer = 6 * 7"
                        it "resolves path with no type constraints", ->
                                r = path.resolve simple_node, ":>expression>left"
                                expect(r.length).toEqual 3
                                for n in r
                                        expect(n).not.toEqual null
                                expect(r[0]).toEqual simple_node
                                expect(r[1]).toEqual simple_node.expression
                                expect(r[2]).toEqual simple_node.expression.left
                        
                        it "resolves path with type constraints", ->
                                p = ":ExpressionStatement>expression:AssignmentExpression>right:BinaryExpression"
                                r = path.resolve simple_node, p
                                expect(r.length).toEqual 3 for n in r
                                expect(n).not.toEqual null
                                expect(r[0]).toEqual simple_node
                                expect(r[1]).toEqual simple_node.expression
                                expect(r[2]).toEqual simple_node.expression.right

                        it "resolves path with array accessor"
                        it "resolves path with array element accessor"
                describe "PathDispatcher", ->
                        it "dispatches simple map"
                        it "dispatches nested map"
                        it "dispatches with return values" 

