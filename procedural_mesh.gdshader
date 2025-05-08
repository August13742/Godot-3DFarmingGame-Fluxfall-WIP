shader_type spatial;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform sampler2D texture5;
uniform sampler2D texture6;


uniform vec4 colour0;
uniform vec4 colour1;
uniform vec4 colour2;
uniform vec4 colour3;
uniform vec4 colour4;
uniform vec4 colour5;
uniform vec4 colour6;

uniform float threshold0;
uniform float threshold1;
uniform float threshold2;
uniform float threshold3;
uniform float threshold4;
uniform float threshold5;
uniform float threshold6;

uniform float sharpness0;
uniform float sharpness1;
uniform float sharpness2;
uniform float sharpness3;
uniform float sharpness4;
uniform float sharpness5;
uniform float sharpness6;


uniform int layer_count = 0;
uniform float max_height;
varying vec3 world_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec4 get_texture(int i, vec2 uv) {
	if (i == 0) return texture(texture0, uv);
	if (i == 1) return texture(texture1, uv);
	if (i == 2) return texture(texture2, uv);
	if (i == 3) return texture(texture3, uv);
	if (i == 4) return texture(texture4, uv);
	if (i == 5) return texture(texture5, uv);
	if (i == 6) return texture(texture6, uv);
	return vec4(1.0, 0.0, 1.0, 1.0); // debug magenta
}

float get_threshold(int i) {
	if (i == 0) return threshold0;
	if (i == 1) return threshold1;
	if (i == 2) return threshold2;
	if (i == 3) return threshold3;
	if (i == 4) return threshold4;
	if (i == 5) return threshold5;
	if (i == 6) return threshold6;
	return 1.0;
}

float get_sharpness(int i) {
	if (i == 0) return sharpness0;
	if (i == 1) return sharpness1;
	if (i == 2) return sharpness2;
	if (i == 3) return sharpness3;
	if (i == 4) return sharpness4;
	if (i == 5) return sharpness5;
	if (i == 6) return sharpness6;
	return 0.1;
}

vec4 get_color(int i) {
	if (i == 0) return colour0;
	if (i == 1) return colour1;
	if (i == 2) return colour2;
	if (i == 3) return colour3;
	if (i == 4) return colour4;
	if (i == 5) return colour5;
	if (i == 6) return colour6;
	return vec4(0.0);
}

void fragment() {
	float height = world_pos.y / max_height;

	vec4 final_color = vec4(0.0);
	float total_blend = 0.0;

	for (int i = 0; i < layer_count; i++) {
		float t = get_threshold(i);
		float s = get_sharpness(i);
		float blend = smoothstep(t - s, t + s, height);

		vec4 tex_color = get_texture(i, UV);
		if (tex_color.a == 0.0) {
			tex_color = get_color(i); // fallback to color if texture is missing
		}

		final_color += tex_color * blend;
		total_blend += blend;
	}

	if (total_blend > 0.0) {
		final_color /= total_blend;
	}

	ALBEDO = final_color.rgb;
	//ALBEDO = vec3(height,0,0);
}

