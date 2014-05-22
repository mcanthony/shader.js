// Generated by CoffeeScript 1.6.3
var ASTPathDispatcher, ASTPathResolver, ASTWalker, Base, Fragment, SymbolExtractor, TypeResolver, Vertex, namespace, _ref, _ref1,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

ASTPathResolver = (function() {
  function ASTPathResolver() {}

  ASTPathResolver.prototype.array_rule = /(.*?)\[(\d*)\]/mi;

  ASTPathResolver.prototype.parse = function(path) {
    var arr_cap, id, index, is_arr, node, node_str, node_strs, results, _i, _len, _ref, _ref1;
    node_strs = path.split('>');
    results = [];
    for (_i = 0, _len = node_strs.length; _i < _len; _i++) {
      node_str = node_strs[_i];
      node = node_str.split(':');
      id = (_ref = node[0]) != null ? _ref : '';
      is_arr = false;
      index = -1;
      arr_cap = this.array_rule.exec(id);
      if (arr_cap != null) {
        id = arr_cap[1];
        index = parseInt(arr_cap[2]);
        is_arr = true;
        if (isNaN(index)) {
          index = -1;
        }
      }
      results.push({
        id: id,
        type: (_ref1 = node[1]) != null ? _ref1 : '',
        isArray: is_arr,
        index: index
      });
    }
    return results;
  };

  ASTPathResolver.prototype.resolve = function(root, path) {
    var current, next, next_id, next_type, node, nodes, results, root_node, _i, _len;
    nodes = this.parse(path);
    results = [];
    root_node = nodes.shift();
    console.assert(root_node.id === '', "Expect path_root.id == ''");
    if (root_node.type !== '' && root_node.type !== root.type) {
      root = null;
    }
    results.push(root);
    current = root;
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (current == null) {
        results.push(null);
        continue;
      }
      next_id = node.id;
      next_type = node.type;
      console.assert(next_id !== '', "path_node.id not specified");
      next = current[next_id];
      console.log(node);
      console.log(next);
      if (next != null) {
        if (node.isArray) {
          if (node.index === -1) {
            continue;
          } else {
            next = next[node.index];
          }
        }
        if (next_type !== '' && next.type !== next_type) {
          next = null;
        }
      }
      current = next;
      results.push(current);
    }
    console.log(results);
    return results;
  };

  return ASTPathResolver;

})();

ASTPathDispatcher = (function() {
  function ASTPathDispatcher(map) {
    this.map = map;
    this.resolver = new ASTPathResolver();
  }

  ASTPathDispatcher.prototype.dispatch = function(node) {
    var callback, last, nodes, path, _ref, _results;
    _ref = this.map;
    _results = [];
    for (path in _ref) {
      callback = _ref[path];
      nodes = this.resolver.resolve(node, path);
      last = nodes.pop();
      nodes.unshift(last);
      if (last != null) {
        _results.push(callback != null ? callback.apply(void 0, nodes) : void 0);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  return ASTPathDispatcher;

})();

ASTWalker = (function() {
  function ASTWalker() {}

  ASTWalker.prototype._walk = function(node, accept_before, accept_after) {
    var child, name, _i, _len;
    if (node instanceof Array) {
      for (_i = 0, _len = node.length; _i < _len; _i++) {
        child = node[_i];
        this._walk(child, accept_before, accept_after);
      }
      return;
    }
    if ((node instanceof Object) && (node.type != null)) {
      if (typeof accept_before === "function" ? accept_before(node) : void 0) {
        return;
      }
      for (name in node) {
        child = node[name];
        this._walk(child, accept_before, accept_after);
      }
      if (typeof accept_after === "function") {
        accept_after(node);
      }
      return;
    }
  };

  return ASTWalker;

})();

SymbolExtractor = (function(_super) {
  __extends(SymbolExtractor, _super);

  function SymbolExtractor() {
    this.symbols = [];
  }

  SymbolExtractor.prototype.extractAll = function(fn_list) {
    var fn, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = fn_list.length; _i < _len; _i++) {
      fn = fn_list[_i];
      _results.push(this.extract(fn));
    }
    return _results;
  };

  SymbolExtractor.prototype.extract = function(fn) {
    var assigned, fn_name, p, param, unresolved, _i, _len, _ref,
      _this = this;
    if (fn.type !== "FunctionDeclaration") {
      return;
    }
    fn_name = fn.id.name;
    unresolved = {};
    _ref = fn.params;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      param = _ref[_i];
      p = {
        id: param,
        origin: fn_name,
        scope: 'this',
        type: '_ThisDeclaration',
        init: null,
        isExtNode: true
      };
      this.symbols.push(p);
    }
    this._walk(fn.body, function(body_node) {
      var declaration, _j, _len1, _ref1;
      if (body_node.type !== 'VariableDeclaration') {
        return false;
      }
      _ref1 = body_node.declarations;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        declaration = _ref1[_j];
        declaration.origin = fn_name;
        declaration.scope = fn_name;
        if (declaration.init == null) {
          unresolved[declaration.id.name] = declaration;
        }
        _this.symbols.push(declaration);
      }
      return true;
    });
    assigned = {};
    this._walk(fn.body, function(body_node) {
      var expr, sym;
      if (body_node.type !== 'ExpressionStatement') {
        return false;
      }
      expr = body_node.expression;
      if (expr.type !== 'AssignmentExpression') {
        return true;
      }
      if (expr.left.type !== 'Identifier') {
        return true;
      }
      if (assigned[expr.left.name] != null) {
        return true;
      }
      assigned[expr.left.name] = expr.left;
      sym = unresolved[expr.left.name];
      if (sym != null) {
        sym.defer_init = expr.right;
        return delete unresolved[expr.left.name];
      }
    });
    return console.assert(Object.keys(unresolved).length === 0, "Not all symbols are resolved");
  };

  return SymbolExtractor;

})(ASTWalker);

TypeResolver = (function(_super) {
  __extends(TypeResolver, _super);

  function TypeResolver(known_symbols) {
    this.type_table = {};
  }

  TypeResolver.prototype.resolve = function(symbol) {
    var id, init, scope, _ref;
    scope = symbol.scope;
    id = symbol.id.name;
    if (this.type_table[scope] == null) {
      this.type_table[scope] = {};
    }
    if (this.type_table[scope][id] == null) {
      this.type_table[scope][id] = null;
    }
    if (symbol.value_type != null) {
      return true;
    } else if (this.type_table[scope][id] != null) {
      symbol.value_type = this.type_table[scope][id];
      return true;
    }
    init = (_ref = symbol.init) != null ? _ref : symbol.defer_init;
    if (init == null) {
      return false;
    }
    if (init.type === "NewExpression") {
      this.type_table[scope][id] = symbol.value_type = init.callee.name;
      return true;
    }
    return false;
  };

  TypeResolver.prototype["eval"] = function(scope, ast) {};

  return TypeResolver;

})(ASTWalker);

Base = (function() {
  function Base() {}

  Base.prototype.init = function() {};

  Base.prototype.process = function() {};

  Base.prototype.compile = function() {
    var ast;
    ast = this._parse();
    ast = this._translate(ast);
    return this._generate(ast);
  };

  Base.prototype._parse = function() {
    var init_ast, init_src, process_ast, process_src;
    init_src = this.init.toString().replace("function ", "function init");
    process_src = this.process.toString().replace("function ", "function main");
    init_ast = esprima.parse(init_src).body[0];
    process_ast = esprima.parse(process_src).body[0];
    console.log(init_ast);
    console.log(process_ast);
    return [init_ast, process_ast];
  };

  Base.prototype._translate = function(ast) {
    var extractor, fns, need_resolve, not_all_resolved, resolved_last_run, resolved_total, resolver, sym, symbols, _i, _len;
    extractor = new SymbolExtractor();
    extractor.extractAll(ast);
    symbols = extractor.symbols;
    console.log(symbols);
    fns = [];
    resolved_total = 0;
    resolved_last_run = 1;
    need_resolve = Object.keys(symbols).length;
    resolver = new TypeResolver();
    not_all_resolved = true;
    while (not_all_resolved && resolved_last_run > 0) {
      resolved_last_run = 0;
      for (_i = 0, _len = symbols.length; _i < _len; _i++) {
        sym = symbols[_i];
        if (sym.value_type != null) {
          continue;
        }
        if (resolver.resolve(sym)) {
          resolved_total++;
          resolved_last_run++;
        }
      }
      not_all_resolved = resolved_total < need_resolve;
    }
    console.assert(!not_all_resolved, "Not all symbols' types are resolved (" + resolved_total + "/" + need_resolve + ")");
    console.log(symbols);
    return;
    return {
      symbols: symbols,
      fns: fns
    };
  };

  Base.prototype._generate = function(ast) {
    var glsl;
    return glsl = "";
  };

  return Base;

})();

Vertex = (function(_super) {
  __extends(Vertex, _super);

  function Vertex() {
    _ref = Vertex.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  return Vertex;

})(Base);

Fragment = (function(_super) {
  __extends(Fragment, _super);

  function Fragment() {
    _ref1 = Fragment.__super__.constructor.apply(this, arguments);
    return _ref1;
  }

  return Fragment;

})(Base);

namespace = function(target, name, block) {
  var item, top, _i, _len, _ref2, _ref3;
  if (arguments.length < 3) {
    _ref2 = [(typeof exports !== 'undefined' ? exports : window)].concat(__slice.call(arguments)), target = _ref2[0], name = _ref2[1], block = _ref2[2];
  }
  top = target;
  _ref3 = name.split('.');
  for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
    item = _ref3[_i];
    target = target[item] || (target[item] = {});
  }
  return block(target, top);
};

namespace('ShaderJs', function(exports) {
  exports.Base = Base;
  exports.Fragment = Fragment;
  exports.Vertex = Vertex;
});

namespace('ShaderJs.Compiler', function(exports) {
  exports.SymbolExtractor = SymbolExtractor;
  return exports.TypeResolver = TypeResolver;
});

namespace('ShaderJs.Ast', function(exports) {
  exports.Path = ASTPathResolver;
  exports.Dispatcher = ASTPathDispatcher;
  return exports.Walker = ASTWalker;
});
