shader_type spatial;
render_mode blend_mix, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0); // x,y,w,h in [0,1]
uniform float y_offset = 0.0;
uniform float height_scale = 1.0;
uniform float alpha_threshold = 0.5;

void vertex() {
    //VERTEX.y = y_offset + VERTEX.y * (height_scale / max(height_scale, 1e-6));
	VERTEX.y = y_offset + VERTEX.y * (height_scale);
    UV = uv_rect.xy + UV * uv_rect.zw;
}

void fragment() {
    vec4 tex = texture(albedo_tex, UV);
    if (tex.a < alpha_threshold) {
        discard;
    }
    ALBEDO = tex.rgb;
}