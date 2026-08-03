shader_type canvas_item;

// The approved HUD art has opaque black windows. The color bars are drawn
// between the original frame and this ornament-only pass, so only the dark
// window pixels become transparent while the metalwork and gems stay above.
const vec4 HP_WINDOW = vec4(0.1577, 0.1407, 0.6481, 0.2462);
const vec4 BLOCK_WINDOW = vec4(0.1577, 0.5427, 0.6481, 0.2462);
const float WINDOW_DARK_THRESHOLD = 0.06;

bool inside_rect(vec2 point, vec4 rect) {
	return point.x >= rect.x
		&& point.x <= rect.x + rect.z
		&& point.y >= rect.y
		&& point.y <= rect.y + rect.w;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float brightest_channel = max(pixel.r, max(pixel.g, pixel.b));
	bool inside_bar_window = inside_rect(UV, HP_WINDOW)
		|| inside_rect(UV, BLOCK_WINDOW);
	if (inside_bar_window && brightest_channel < WINDOW_DARK_THRESHOLD) {
		pixel.a = 0.0;
	}
	COLOR = pixel;
}
