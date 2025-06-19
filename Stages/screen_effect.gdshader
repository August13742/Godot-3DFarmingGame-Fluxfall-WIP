shader_type canvas_item;


uniform sampler2D screen_texture:hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 screen_colour = texture(screen_texture, SCREEN_UV);
	
	
	float luminance = screen_colour.r * 0.2126 + screen_colour.g * 0.7152 + screen_colour.b * 0.0722;
	COLOR.rgb = vec3((luminance)/3.);

}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
