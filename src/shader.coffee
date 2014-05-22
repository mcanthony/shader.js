# Helper class for resloving AST path
#
# ### Path Syntax
# ```
# RootNode:
#     ':'
#     ':' AstType
# AstNode:
#     ':'
#     Identifier
#     Identifier ':' AstType
# AstPath:
#     RootNode
#     AstPath '>' AstNode
# ```
# Notes:
# * `Identifier` field is used to search a node in AST
# * `AstType` field is used for node type validation
# * First node's `Identifier` field should always be empty
# @example Some valid pathes
#   # assert root.type == 'FunctionDeclaration'
#   ':FunctionDeclaration'
#   # get root.expr.left
#   ':>expr>left'
#   # get root.expr.left and assert each node's type
#   ':ExpressionStatement>expr:AssignmentExpression>left:Identifier'
# @todo Implement Array accessor syntax
class ASTPathResolver
        # Parse a path
        # @param {string} path The path string
        # @return {Array} An array of path nodes (format: `{id: identifier, type: ast_type}`)
        parse: (path) ->
                node_strs = path.split '>'
                results = []
                for node_str in node_strs
                        node = node_str.split ':'
                        results.push
                                id: node[0] ? ''
                                type: node[1] ? ''
                return results
        # Resove given path string from specified root
        # @param {object} root The root AST node
        # @path {string} path The path string
        # @return {object} The node specified by path. The value will be `null` if path is not valid
        resolve: (root, path) ->
                nodes = @parse path
                
                # handle root node
                root_node = nodes.shift()
                # root should not have id
                console.assert root_node.id == '', "Expect path_root.id == ''"
                # check type
                if root_node.type != '' and root_node.type != root.type
                        return null
                # root matched
                current = root
                # the rest
                for node in nodes
                        next_id = node.id
                        next_type = node.type
                        # must have id
                        console.assert next_id != '', "path_node.id not specified"
                        # get next
                        next = node[next_id]
                        # check existance
                        if not current? then return null
                        # check type
                        if next_type != '' and next.type != next_type then return null
                        # all ok
                        current = next
                # done
                return current
                
# Match AST node path and dispatch method calls
# @todo Pass path nodes in reverse order to callbacks
# @todo Collect return values
class ASTPathDispatcher
        # Create an instance of this class
        # @param {object} map The dispatch map
        # @example Map format
        #   map =
        #     ':FunctionDeclaration': (node) ->
        #       # do stuff with the node
        #     ':ExpressionStatement>expr:AssignmentExpression>left:Identifier': (node)->
        #       # do stuff with the node
        constructor: (@map) ->
                @resolver = new ASTPathResolver()

        dispatch: (node) ->
                for path, callback of @map
                        node = @resolver.resolve node, path
                        if node? then callback? node
                                
# Base class with helper methods for walking AST
class ASTWalker
        # Walk AST with visitor
        # @param {object} node The node of AST to walk
        # @param {(bool) function(object)} accept_before The visitor callback called before chilren are visited. The node being visited is passed as the only argument. Returns `true` if it wishes to stop walking further down.
        # @param {(void) function(object)} accept_after The visitor callback called after children are visited. The node being visited is passed as the only argument. 
        # @note Internal use only
        # @example Walk and `console.log` each node's type
        #   @_walk ast, (node) ->
        #     console.log node
        #     # don't stop, walk further down
        #     return false
        # @example Walk `FunctionDeclaration`s only
        #   @_walk ast, (node) ->
        #     if node.type != "FunctionDeclaration"
        #       return false
        # 
        #     # TODO: do some stuff here (eg. extract signature)
        # 
        #     # stop now
        #     return true
        # @see https://developer.mozilla.org/en-US/docs/Mozilla/Projects/SpiderMonkey/Parser_API Mozilla SpiderMonkey Parser API
        # @see http://esprima.org/doc/index.html#ast Esprima Syntax Tree Format
        # @see http://esprima.org/demo/parse.html Esprima Parser Demo
        _walk: (node, accept_before, accept_after) ->
                # If node is an Array, walk each element but not the array
                if node instanceof Array
                        for child in node
                                @_walk child, accept_before, accept_after
                        return
                # Ast node is an object with `type` field
                if (node instanceof Object) and node.type?
                        # visit this node before
                        if accept_before? node
                                # visitor don't want to walk further
                                return
                        # walk children
                        for name, child of node
                                @_walk child, accept_before, accept_after
                        # visit this node after
                        accept_after? node
                        return
                # Just ignore any other types
                return
        
# Extract symbols from a `FunctionDeclaration` node
class SymbolExtractor extends ASTWalker
        # Create an instance of this class
        constructor: ->
                @symbols = []

        # Extract all symbols from an Array of `FunctionDeclaration` AST nodes
        # See {extract} method for more information.
        # @param {Array} fn_list An array of `FunctionDeclaration` AST nodes
        extractAll: (fn_list) ->
                for fn in fn_list
                        @extract fn

        # Extract all symbols from one `FunctionDeclaration` AST node.
        # All extracted symbols are in the form of `VariableDeclaration` nodes
        # and are stored in {@symbols} with some of the following fields added:
        # 
        # Field Name  | Description
        # ----------  | -----------
        # `origin`    | The origin of this symbol identified with function's name
        # `scope`     | The scope of this symbol identified with either `this` or function's name
        # `defer_init`| If `init` field is `null`, this method will find first asignment to this symbol and set to this field
        # 
        # A few remarks on symbols extracted from function's arguments:
        # * They are put in `this` scop since they will be later used as an property of its class
        # * Their types are `_ThisDeclaration`
        # * An additional field `isExtNode` = `true` is added to each one to identify them as non-standard AST
        # @param {object} fn A `FunctionDeclaration` AST node
        extract: (fn) ->
                if fn.type != "FunctionDeclaration"
                        # TODO: error information
                        return
                        
                # function name
                fn_name = fn.id.name
                # Keep track of symbols that are declared but not initialized
                unresolved = {}
                                
                # Pass 1: extract symbols
                # function parameters
                for param in fn.params
                        # Push to symbol table
                        # Symbol's format matchs 'VariableDecalration'
                        p =
                                id: param
                                origin: fn_name # Keep track of origin
                                scope: 'this'   # Keep track of scope
                                type: '_ThisDeclaration' # Extened node all starts with _
                                init: null      # Not initialized
                                isExtNode: true # Extended node, not part of Esprima's original spec
                        # Push symbol
                        @symbols.push p

                # Local symbols' types are inferred from first assignments
                # Nested visit body for local symbols
                @_walk fn.body, (body_node) =>
                        if body_node.type != 'VariableDeclaration'
                                return false
                        for declaration in body_node.declarations
                                # Scope and origin are both identified by fn_name
                                declaration.origin = fn_name
                                declaration.scope = fn_name
                                # If not initialized, need resolve
                                if not declaration.init?
                                        # TODO: throw warning for re-declaration
                                        unresolved[declaration.id.name] = declaration
                                # Push as a whole for infering types
                                @symbols.push declaration
                        # don't walk further down
                        return true

                # Keep track of assigned symbols
                assigned = {}
                # Pass 2: resolve symbols
                @_walk fn.body, (body_node) =>
                        # We want an expression
                        if body_node.type != 'ExpressionStatement'
                                return false
                        expr = body_node.expression
                        # It must be assignment
                        if expr.type != 'AssignmentExpression'
                                return true
                        # Left value must be an identifier
                        if expr.left.type != 'Identifier'
                                return true
                        # Is assigned for the first time?
                        if assigned[expr.left.name]?
                                return true
                        # Yes it is
                        assigned[expr.left.name] = expr.left
                        # Is it unresolved?
                        sym = unresolved[expr.left.name]
                        # Yes it is
                        if sym?
                                # Deferred initialization
                                sym.defer_init = expr.right
                                # Remove from unresolved list
                                delete unresolved[expr.left.name]

                # All symbols should be resolved by now
                # TODO: throw errors properly
                console.assert Object.keys(unresolved).length == 0, "Not all symbols are resolved"
                                
# Resolve symbol's type
class TypeResolver extends ASTWalker
        # Create a TypeResolver instance
        # @param {object} known_symbols A list of symbols with known types
        constructor: (known_symbols)->
                @type_table = {}
        # Resolve a symbol's type from initialization
        # @param {object} symbol The symbol to be resolved
        # @return {bool} A bool value indicates wheter the type information has been resolved. 
        resolve: (symbol) ->
                scope = symbol.scope
                id = symbol.id.name

                if not @type_table[scope]?
                        @type_table[scope] = {}
                if not @type_table[scope][id]?
                        @type_table[scope][id] = null

                # Already resolved
                if symbol.value_type?
                        return true
                else if @type_table[scope][id]?
                        symbol.value_type = @type_table[scope][id]
                        return true

                # Try resolve
                init = symbol.init ? symbol.defer_init
                if not init?
                        return false
                if init.type == "NewExpression"
                        @type_table[scope][id] = symbol.value_type = init.callee.name
                        return true
                # TODO: build-in factory function call
                return false

        # Evaluate an AST node and try to infer symbol's type information from it.
        # All known symbols should be decalred by either {constructor} or {resolve}.
        # Errors will be thrown if one of the following happens:
        # * undecalred symbols are encontered
        # * type confilict
        # @param {string} scope The scope of the AST node
        # @param {ast} ast The AST node to be evaluated
        # @return {bool] True if there are no symbols to be resolved or all symbols are resolved
        eval: (scope, ast) ->
                # TODO: 

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

# Base class for a shaders.
# @note Interal use only. Shader developers should **never** extend from this class
class Base
        # Implement in derived class by shader developer.
        # Arguments are compiled as `uniform`s
        # @note This method is staticly analysed. It will and should **never** be called at runtime.
        # @note Always leave the body empty.
        init: ->

        # Implement in derived class by shader developer.
        # Body of this method is staticly analysed and compiled to `main()` procedure of GLSL.
        # Arguments of this method are for sematic purpose only and have diffrent meanings in diffrent shaders:
        # * for {Vertex} shader, arguments are compiled as `uniform`s
        # * for {Fragment} shader, arguments are compiled as `varying`s
        # @note Only a small subset of JavaScript's language features are supported in this method.
        # @note This method is staticly analysed. It will and should **never** be called at runtime.
        # @return {Array} {Fragment} shader should return an array of values, which will be compiled as `varying`s and passed to next shader in the pipline.
        process: ->

        # Compile this class into GLSL shader
        compile: ->
                # Parse self
                ast = @_parse()
                # Translate AST
                ast = @_translate ast
                # Generate GLSL
                return @_generate ast

        # Parse this instance into AST
        # @return {Array} Array of raw AST for each methods (including {@init} and {@process})
        # @note Internal use only
        _parse: ->
                # Get source codes of methods
                init_src = @init.toString().replace "function ", "function init"
                process_src = @process.toString().replace "function ", "function main"

                # TODO: get other user defined methods
                # TBD: get consts

                # Parse ast for methods
                init_ast = esprima.parse(init_src).body[0]
                process_ast = esprima.parse(process_src).body[0]

                console.log init_ast
                console.log process_ast

                # TODO: get parameters
                # TODO: infer parameters' type somehow
                # TODO: validate method body for:
                #    1. unsupported js language features (error)
                #    2. external function call (error)
                #    3. @position not set (warning)
                #    4. unused variables (warning)
                #    5. no return value (warning if 4)
                #    6. unknown type (error)
                #    7. unresolved symbols like @xxx (error)
                # TODO: translate AST
                #    1. @xxx
                #    2. initialization
                # TODO: compile and return ast
                return [init_ast, process_ast]
                
        # Translate raw AST for GLSL generation
        # @param {Array} ast The raw AST returned by {Base._parse} method
        # @return {object} Translated AST
        # @note Internal use only
        _translate: (ast) ->
                extractor = new SymbolExtractor()
                # symbol table
                # element type: esprima ast element
                extractor.extractAll ast
                symbols = extractor.symbols
                console.log symbols
                # functions
                # element type: {id: fn_id, ast: fn_ast}
                fns = []
                
                # Pass 3: resolve symbol types and references
                # Note: There are no type information for method arguments,
                #       thus the type information has to be inferred from usage.
                #       Locals are relatively easy since they have to be intialized.
                #       There're two scenerios:
                #       1. Initialized by NewExpression
                #       2. Initialized by expression
                #       A reference tree/graph should be built first.
                #       Symbols of S1 are leafs while other are nodes.
                #       Type information can be then calculated bottom up.
                resolved_total = 0
                resolved_last_run = 1
                need_resolve = Object.keys(symbols).length
                resolver = new TypeResolver()
                not_all_resolved = true
                while not_all_resolved and resolved_last_run > 0
                        resolved_last_run = 0
                        for sym in symbols
                                # Type already resolved
                                if sym.value_type?
                                        continue
                                if resolver.resolve sym
                                        resolved_total++
                                        resolved_last_run++
                        not_all_resolved = resolved_total < need_resolve
                        
                # TODO: throw errors properly
                console.assert not not_all_resolved, "Not all symbols' types are resolved (#{resolved_total}/#{need_resolve})"
                
                # TODO: determin symbol keywords
                #    1. attributes
                #    2. varyings
                #    3. uniforms
                        
                # TODO: validate @xxx symbols and translate to
                #    1. built-ins (gl_Position, color, etc)
                #    2. uniforms
                # TODO: extract symbol declarations from arguments for
                #    1. attributes
                #    2. varyings
                #    3. uniforms
                # TODO: extract varying symbol declartions from return directive
                # TODO: translate object creation call
                # TODO: infer object types
                # TODO: validate symbol references
                console.log symbols
                return
                symbols: symbols
                fns: fns

        # Generate GLSL from translated AST
        # @param {object} ast The translated AST returned by {Base._translate} method
        # @return {object} Generation results including GLSL source code, source map, warnings and errors
        # @note Internal use only
        _generate: (ast) ->
                glsl = ""

                # TODO: symbol decalrations
                # TODO: generate body (without return)
                # TODO: generate vary from return
                # TODO: generate uniform from init(arguments)
                # TODO: generate attribute from process(arguments)
                # TBD: generate consts

# Base class for all vertex shader class
class Vertex extends Base

# Base class for all fragment shader class
class Fragment extends Base
        
namespace 'ShaderJs', (exports) ->
        exports.TypeResolver = TypeResolver
        exports.Base = Base
        exports.Fragment = Fragment
        exports.Vertex = Vertex
        return
