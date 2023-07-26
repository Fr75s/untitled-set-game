shader_type canvas_item;

uniform vec4 old_color;
uniform vec4 new_color;

void fragment() {
	// Place fragment code here.
	vec4 current_pixel = texture(TEXTURE, UV);
	
	if (current_pixel == old_color) {
		COLOR = new_color;
	} else {
		COLOR = current_pixel;
	}
}
