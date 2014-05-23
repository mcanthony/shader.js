# Helper class for resloving AST path
#
# ### Path Syntax
# ```
# TypeValidator:
#     ':'
#     ':' AST_TYPE
# ArrayElement:
#     '[' INDEX ']'
# ArrayMapping:
#     '[' ']'
# ArrayAccessor:
#     ArrayElement
#     ArrayMapping
# UnnamedNode:
#     TypeValidator
#     ArrayAccessor TypeValidator
# RootNode:
#     UnnamedNode
# AstNode:
#     Identifier
#     Identifier UnnamedNode
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
#   # root is an array, walk each element and map results to an Array of the same dimension
#   '[]:>id>left'
#   # root is an array, get first element and walk from there
#   '[0]:>id>left'
#   # a more complex syntax: type validator + array mapping
#   ':VariableDeclaration>declarations[]:VariableDeclarator>id:Identifier'
class ASTPathResolver
        # @nodoc
        array_rule: ///(.*?)\[(\d*)\]///mi
        # Parse a path
        # @param {string} path The path string
        # @return {Array} An array of path nodes (format: `{id: identifier, type: ast_type}`)
        parse: (path) ->
                node_strs = path.split '>'
                results = []
                for node_str in node_strs
                        node = node_str.split ':'
                        id = node[0] ? ''
                        is_arr = false
                        index = -1
                        arr_cap = @array_rule.exec id
                        if arr_cap?
                                id = arr_cap[1]
                                index = parseInt arr_cap[2]
                                is_arr = true
                                if isNaN index then index = -1
                        results.push
                                id: id
                                type: node[1] ? ''
                                isArray: is_arr
                                index: index
                return results
                
        # Resolve given path string from specified root
        # @param {object} root The root AST node
        # @param {string} path The path string
        # @return {Array} An array of each AST node in the path. Each element's value will be `null` if the corresponding path node is not valid.
        resolve: (root, path) ->
                nodes = @parse path
                @_resolve root, nodes

        # Resolve parsed path from specified root
        # @note Internal use only
        # @param {object} root The root AST node
        # @param {Array} nodes Parsed path
        # @return {Array} An array of each AST node in the path. Each element's value will be `null` if the corresponding path node is not valid.
        _resolve: (root, nodes) ->
                results = []
                # handle array
                if root instanceof Array
                        console.assert nodes[0].isArray, "Expect path_root.isArray == true"
                        for child in root
                                r = @_resolve child, nodes
                                if r instanceof Array and r.length == 1
                                        results.push r[0]
                                else
                                        results.push r
                        return results

                # check length
                if nodes.length == 0
                        return results
                # handle root node
                root_node = nodes.shift()
                # root should not have id
                # TODO: might not be necessary
                console.assert root_node.id == '', "Expect path_root.id == ''. Actual: #{root_node.id}"
                # check type
                if root_node.type != '' and root_node.type != root.type
                        root = null
                # push root
                results.push root
                # root matched
                current = root
                # the rest
                for node, i in nodes
                        # Not valid, perserve counts (if no array)
                        if not current?
                                results.push null
                                continue
                        next_id = node.id
                        next_type = node.type

                        # must have id
                        console.assert next_id != '', "path_node.id not specified"
                        # get next
                        next = current[next_id]
                        # check existance
                        if next?
                                # Is array?
                                if node.isArray
                                        if node.index == -1
                                                # Capture all
                                                # Note: need review.
                                                #       `nodes` is not deep-copied but modified
                                                #       in place.
                                                #       May cause bugs by this side effect 
                                                n = []
                                                remaining_nodes = nodes[i..]
                                                # remaining_nodes[0].id = ""
                                                # remaining_nodes[0].isArray = false
                                                results.push @_resolve next, remaining_nodes
                                                break
                                        else
                                                # capture element
                                                next = next[node.index]
                                                
                                # check type
                                if next_type != '' and next.type != next_type
                                        next = null
                        # all ok
                        current = next
                        # push
                        results.push current
                # restore root
                nodes.unshift root_node
                # done
                return results
                
# Match AST node path and dispatch method calls
# @todo Pass path nodes in reverse order to callbacks
# @todo Collect return values
# @todo Nested dispatch
class ASTPathDispatcher
        # Create an instance of this class
        # @param {object} map The dispatch map
        # @example Map format
        #   map =
        #     ':FunctionDeclaration': (fn) ->
        #       # do stuff with the node
        #     # The last AST node in path is passed first. Then the result are passed in order.
        #     ':ExpressionStatement>expr:AssignmentExpression>left:Identifier': (id, root, expr)->
        #       # do stuff with the node
        constructor: (@map) ->
                @resolver = new ASTPathResolver()

        # Receive a node as root and resolve pathes from there.
        # If any path in the map can be resloved from specified node,
        # the method registered in that path will be invoked.
        # @param {object} node The AST node
        dispatch: (node) ->
                for path, callback of @map
                        nodes = @resolver.resolve node, path
                        # pop the last one and pass it first
                        last = nodes.pop()
                        nodes.unshift last
                        if last? then callback?.apply undefined, nodes
                                
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
