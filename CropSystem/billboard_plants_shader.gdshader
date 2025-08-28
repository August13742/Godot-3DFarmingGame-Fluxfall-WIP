shader_type spatial;
render_mode blend_mix, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float scale_factor = 1.0;
uniform float vertical_offset = 0.0;
uniform float alpha_threshold = 0.5;

void vertex() {
    // Apply scaling to maintain aspect ratio
    VERTEX.y = vertical_offset + VERTEX.y * scale_factor;

    UV = uv_rect.xy + UV * uv_rect.zw;
}

void fragment() {
    vec4 tex = texture(albedo_tex, UV);
    if (tex.a < alpha_threshold) {
        discard;
    }
    ALBEDO = tex.rgb;
}