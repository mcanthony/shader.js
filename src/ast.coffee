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
