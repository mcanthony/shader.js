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

        # Walk AST with visitor
        # @param {object} node The node of AST to walk
        # @param {(bool) function(object)} accept The visitor callback with the visiting node passed as the only argument. Returns `true` if it wishes to stop walking further down.
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
        _walk: (node, accept) ->
                # If node is an Array, walk each element but not the array
                if node instanceof Array
                        for child in node
                                @_walk child, accept
                        return
                # Ast node is an object with `type` field
                if (node instanceof Object) and node.type?
                        # visit this node first
                        if accept? node
                                # visitor don't want to walk further
                                return
                        # walk children
                        for name, child of node
                                @_walk child, accept
                        return
                # Just ignore any other types
                return
                
        # Translate raw AST for GLSL generation
        # @param {Array} ast The raw AST returned by {Base._parse} method
        # @return {object} Translated AST
        # @note Internal use only
        _translate: (ast) ->
                # symbol table
                # element type: esprima ast element
                symbols = []
                # functions
                # element type: {id: fn_id, ast: fn_ast}
                fns = []
                # TODO: implement tree visitor
                for fn in ast
                        # Note: we will walk AST in multiple pass
                        #       instead of one pass with tons of if..else
                        
                        # Pass 1: extract symbol declarations from arguments
                        @_walk fn, (node) ->
                                if node.type != "FunctionDeclaration"
                                        return false
                                # function name
                                fn_name = node.id.name
                                # function parameters
                                for param in node.params
                                        # Keep track of origin
                                        param.orign = fn_name
                                        # Push to symbol table 
                                        symbols.push param
                                # don't walking further down
                                return true
                        # TODO: determin symbol types
                        #    1. attributes
                        #    2. varyings
                        #    3. uniforms
                                        

                        # TODO: all translating stuff
                        fns.push fn
                        
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
        exports.Base = Base
        exports.Fragment = Fragment
        exports.Vertex = Vertex
        return
