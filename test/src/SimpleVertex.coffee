define (require, exports, module) ->
        ShaderJs = window.ShaderJs
        
        exports = class SimpleVertex extends ShaderJs.Vertex
                init: (@mvp_mat, @normal_mat, @light_dir) ->
                        
                process: (pos, normal, uv) ->
                        
