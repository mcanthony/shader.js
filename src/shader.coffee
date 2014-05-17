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
                        init_src = @init.toString()
                        process_src = @process.toString()

                        # TODO: get other user defined methods
                        # TBD: get consts

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
