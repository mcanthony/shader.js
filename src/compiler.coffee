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
