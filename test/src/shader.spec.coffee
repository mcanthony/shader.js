define (require, exports, module) ->
        exports = describe "Shader.Js", ->
                describe "Environment", ->
                        it "has dependency 'Esprima'", ->
                                expect(esprima?).toBe true
                        it "has namespace 'window.ShaderJs'", ->
                                expect(window.ShaderJs?).toBe true
                        it "has class 'Base'", ->
                                expect(window.ShaderJs.Base?).toBe true
                        it "has class 'Vertex'", ->
                                expect(window.ShaderJs.Vertex?).toBe true
                        it "has class 'Fragment'", ->
                                expect(window.ShaderJs.Fragment?).toBe true
                describe "Base", ->
                        it "parses AST"
                describe "Vertex", ->
                        SimpleVertex = require './SimpleVertex'
                        it "generates vertex shader", ->
                                vertex_shader = new SimpleVertex()
                                vertex_shader.compile()
                describe "Fragment", ->
                        it "generates fragment shader"

                        
