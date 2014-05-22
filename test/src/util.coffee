define (require, exports, module) ->
        exports =
                strip: (program) ->
                        return program.body[0]
                parseOne: (js_line) ->
                        return @strip esprima.parse js_line
