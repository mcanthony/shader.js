// Generated by CoffeeScript 1.6.3
define(function(require, exports, module) {
  return exports = describe("Shader.Js", function() {
    describe("Environment", function() {
      it("has dependency 'Esprima'", function() {
        return expect(typeof esprima !== "undefined" && esprima !== null).toBe(true);
      });
      it("has namespace 'window.ShaderJs'", function() {
        return expect(window.ShaderJs != null).toBe(true);
      });
      it("has class 'Base'", function() {
        return expect(window.ShaderJs.Base != null).toBe(true);
      });
      it("has class 'Vertex'", function() {
        return expect(window.ShaderJs.Vertex != null).toBe(true);
      });
      return it("has class 'Fragment'", function() {
        return expect(window.ShaderJs.Fragment != null).toBe(true);
      });
    });
    describe("Base", function() {
      return it("parses AST");
    });
    describe("Vertex", function() {
      var SimpleVertex;
      SimpleVertex = require('./SimpleVertex');
      return it("generates vertex shader", function() {
        var vertex_shader;
        vertex_shader = new SimpleVertex();
        return vertex_shader.compile();
      });
    });
    return describe("Fragment", function() {
      return it("generates fragment shader");
    });
  });
});
