# Delcare namespace
# @param {object} target The target to attach this namespace (optional). Default to `windows` (browser) or `exports` (node.js)
# @param {string} name The name of this namespace seperated with dots
# @param {function(obj)} block The callback for attaching objects to namespace
# @example declare a class inside a namespace
#   namespace 'foo', (exports) ->
#     exports = class Bar
# @example declare a named function inside a namespace
#   namespace 'foo', (exports) ->
#     exports.fn = ->
namespace = (target, name, block) ->
        [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
        top    = target
        target = target[item] or= {} for item in name.split '.'
        block target, top

namespace 'ShaderJs', (exports) ->
        exports.Base = Base
        exports.Fragment = Fragment
        exports.Vertex = Vertex
        return

namespace 'ShaderJs.Compiler', (exports) ->
        exports.SymbolExtractor = SymbolExtractor
        exports.TypeResolver = TypeResolver

namespace 'ShaderJs.Ast', (exports) ->
        exports.Path = ASTPathResolver
        exports.Dispatcher = ASTPathDispatcher
        exports.Walker = ASTWalker
