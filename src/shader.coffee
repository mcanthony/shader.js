# Namespace
namespace = (target, name, block) ->
        [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
        top    = target
        target = target[item] or= {} for item in name.split '.'
        block target, top

namespace 'ShaderJs', (exports) ->
        exports.Base = class Base
                init: ->
                        # Implement in derived classes
                        # Arguments of this method will be compiled as uniforms
                        # @setXxx methods will be created for each arguments

                process: ->
                        # Implement in derived classes
                        # Arguments of this method will be compiled as
                        #   attributes (vertex shader) or varying (fragment shader)
                        # Vertex shader returns an array whose elements will be comiled as varying

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

                        console.log init_ast
                        console.log process_ast

                        # Parse ast for methods
                        init_ast = esprima.parse(init_src).body[0]
                        process_ast = esprima.parse(process_src).body[0]

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

        exports.Fragment = class Fragment extends Base

        exports.Vertex = class Vertex extends Base

        # End of namespace
        return
