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
