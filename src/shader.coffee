# Delcare namespace
# @param {object} target the target to attach this namespace (optional). Default to `windows` (browser) or `exports` (node.js)
# @param {string} name the name of this namespace seperated with dots
# @param {function(obj)} block the callback for attaching objects to namespace
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
                # Implement in derived classes
                # Arguments of this method will be compiled as uniforms
                # @setXxx methods will be created for each arguments

        # Implement in derived class by shader developer.
        # Body of this method is staticly analysed and compiled to `main()` procedure of GLSL.
        # Arguments of this method are for sematic purpose only and have diffrent meanings in diffrent shaders:
        # * for {Vertex} shader, arguments are compiled as `uniform`s
        # * for {Fragment} shader, arguments are compiled as `varying`s
        # @note Only a small subset of JavaScript's language features are supported in this method.
        # @note This method is staticly analysed. It will and should **never** be called at runtime.
        # @return {Array} {Fragment} shader should return an array of values, which will be compiled as `varying`s and passed to next shader in the pipline.
        process: ->
                # Implement in derived classes
                # Arguments of this method will be compiled as
                #   attributes (vertex shader) or varying (fragment shader)
                # Vertex shader returns an array whose elements will be comiled as varying

        # Compile this class into GLSL shader
        compile: ->
                # Parse self
                ast = @parse()
                # Generate GLSL
                @generate ast

        parse: ->
                # Get source codes of methods
                init_src = @init.toString().replace "function ", "function init"
                process_src = @process.toString().replace "function ", "function init"

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
                return []

        generate: (ast) ->
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
