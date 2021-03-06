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
                                expect(r.length).toEqual 3
                                for n in r
                                        expect(n).not.toEqual null
                                expect(r[0]).toEqual simple_node
                                expect(r[1]).toEqual simple_node.expression
                                expect(r[2]).toEqual simple_node.expression.right

                        # make test data
                        fn_node = Util.parseOne "function foo(a, b) {}"
                        it "resolves path with array accessor", ->
                                p = ":FunctionDeclaration>params[]:Identifier"
                                r = path.resolve fn_node, p
                                expect(r.length).toEqual 2
                                for n in r
                                        expect(n).not.toEqual null
                                expect(r[0]).toEqual fn_node
                                expect(r[1]).toEqual fn_node.params
                                expect(r[1] instanceof Array).toBe true
                                for id in r[1]
                                        expect(id).not.toEqual null
                                
                        it "resolves path with array element accessor", ->
                                p = ":FunctionDeclaration>params[0]:Identifier"
                                r = path.resolve fn_node, p
                                expect(r.length).toEqual 2
                                for n in r
                                        expect(n).not.toEqual null
                                expect(r[0]).toEqual fn_node
                                expect(r[1]).toEqual fn_node.params[0]

                        it "resolves root array", ->
                                p = "[]:Identifier"
                                r = path.resolve fn_node.params, p
                                expect(r.length).toEqual 2
                                for n, i in r
                                        expect(n).toEqual fn_node.params[i]

                        declare_node = Util.parseOne "var foo = 1, bar = 2"
                        it "resolves path with array element mapping", ->
                                p = ":VariableDeclaration>declarations[]:VariableDeclarator>id:Identifier"
                                r = path.resolve declare_node, p
                                expect(r.length).toEqual 2
                                for n in r
                                        expect(n).not.toEqual null
                                expect(r[1] instanceof Array).toEqual true
                                expect(r[1].length).toEqual 2
                                for n in r[1]
                                        expect(n).not.toEqual null
                                
                describe "PathDispatcher", ->
                        it "dispatches simple map"
                        it "dispatches nested map"
                        it "dispatches with return values" 

