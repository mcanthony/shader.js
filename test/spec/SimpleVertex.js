// Generated by CoffeeScript 1.6.3
var SimpleVertex, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

SimpleVertex = (function(_super) {
  __extends(SimpleVertex, _super);

  function SimpleVertex() {
    _ref = SimpleVertex.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  SimpleVertex.prototype.init = function(mvp_mat, normal_mat, light_dir) {
    this.mvp_mat = mvp_mat;
    this.normal_mat = normal_mat;
    this.light_dir = light_dir;
  };

  SimpleVertex.prototype.process = function(pos, normal, uv) {};

  return SimpleVertex;

})(ShaderJs.Vertex);

define(function(require, exports, module) {
  var ShaderJs;
  ShaderJs = window.ShaderJs;
  return exports = SimpleVertex;
});
