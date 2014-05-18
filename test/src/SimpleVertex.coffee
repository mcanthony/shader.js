# @nodoc
class SimpleVertex extends ShaderJs.Vertex
        init: (@mvp_mat, @normal_mat, @light_dir) ->

        process: (pos, normal, uv) ->
                # position is gl_Position
                @position = @mvp_mat * pos

                trans_normal = normal_mat * new Vec4(normal, 1)

                # Return array contains varying
                return [uv.st, max dot(trans_normal.xyz, @light_dir), 0.0]
                
define (require, exports, module) ->
        ShaderJs = window.ShaderJs
        
        exports = SimpleVertex
                        
