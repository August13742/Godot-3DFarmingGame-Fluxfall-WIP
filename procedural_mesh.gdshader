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

uniform int layer_count = 7;
uniform float max_height = 40.0;
uniform float scale = 0.1;

varying vec3 world_pos;
varying vec3 local_pos;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX;
}

vec4 triplanar_sample(sampler2D tex, vec3 pos, vec3 norm) {
    vec3 blending = abs(norm);
    blending = normalize(max(blending, 0.0001)); // avoid div0

    vec2 x_uv = pos.yz * scale;
    vec2 y_uv = pos.xz * scale;
    vec2 z_uv = pos.xy * scale;

    vec4 x = texture(tex, x_uv);
    vec4 y = texture(tex, y_uv);
    vec4 z = texture(tex, z_uv);
	// sRGB to linear correction
	//x.rgb = pow(x.rgb, vec3(2.2));
	//y.rgb = pow(y.rgb, vec3(2.2));
	//z.rgb = pow(z.rgb, vec3(2.2));

    return x * blending.x + y * blending.y + z * blending.z;
}

vec4 get_layer_color(int i, vec3 pos, vec3 norm) {
    if (i == 0) return triplanar_sample(texture0, pos, norm);
    if (i == 1) return triplanar_sample(texture1, pos, norm);
    if (i == 2) return triplanar_sample(texture2, pos, norm);
    if (i == 3) return triplanar_sample(texture3, pos, norm);
    if (i == 4) return triplanar_sample(texture4, pos, norm);
    if (i == 5) return triplanar_sample(texture5, pos, norm);
    if (i == 6) return triplanar_sample(texture6, pos, norm);
    return vec4(1.0, 0.0, 1.0, 1.0); // debug magenta
}

vec4 get_fallback_color(int i) {
    if (i == 0) return colour0;
    if (i == 1) return colour1;
    if (i == 2) return colour2;
    if (i == 3) return colour3;
    if (i == 4) return colour4;
    if (i == 5) return colour5;
    if (i == 6) return colour6;
    return vec4(0.0);
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
vec3 layer_debug_color(int i) {
	if (i == 0) return vec3(0.0, 0.0, 1.0); // Blue - Water
	if (i == 1) return vec3(1.0, 1.0, 0.0); // Yellow - Sand
	if (i == 2) return vec3(0.0, 1.0, 0.0); // Green - Grass
	if (i == 3) return vec3(0.8, 0.6, 0.4); // 
	if (i == 4) return vec3(0.0, 0.0, 0.0); // b
	if (i == 5) return vec3(1.0, 0.0, 0.0); // r
	if (i == 6) return vec3(1.0, 1.0, 1.0); // white
	return vec3(1.0, 0.0, 1.0); // Magenta - Unknown
}


void fragment() {
    float height = local_pos.y / max_height;
    vec3 norm = normalize(NORMAL);

    vec4 final_color = vec4(0.0);
	
    float total_weight = 0.0;

    for (int i = 0; i < layer_count; i++) {
		//float height_start = (i == 0) ? get_threshold(i-1):0.0;
		float height_start = get_threshold(i);
		float height_end = (i < layer_count-1) ? get_threshold(i+1):1.0;
		float blend = get_sharpness(i);
		
		float w_in = smoothstep(height_start-blend, height_start, height); // fade in
		float w_out = 1.0 - smoothstep(height_end,height_end+blend, height); // fade out
		float w = clamp(w_in*w_out,0.0,1.0);
		
		vec4 layer_col = get_layer_color(i,local_pos,norm);
		layer_col.a = 1.0;
		
		layer_col.rgb = pow(layer_col.rgb, vec3(1.5)); // boosts midtones
		
		final_color.rgb += layer_col.rgb*w;
		total_weight += w;
		
    }

    if (total_weight > 0.0) {
        final_color.rgb /= total_weight;
    }
	
    //ALBEDO = final_color.rgb;
	ALBEDO = clamp(final_color.rgb, 0.0, 1.0);
}



