shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// --- Sun Light ---
uniform vec2 sun_position = vec2(0.5, 0.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.88, 0.55, 1.0);
uniform float sun_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float sun_radius : hint_range(0.01, 2.0) = 1.0;

// --- Ambient ---
uniform vec4 ambient_color : source_color = vec4(0.12, 0.08, 0.22, 1.0);
uniform float ambient_intensity : hint_range(0.0, 2.0) = 0.7;

// --- Vignette ---
uniform float vignette_intensity : hint_range(0.0, 3.0) = 1.4;
uniform float vignette_smoothness : hint_range(0.01, 1.0) = 0.45;

// --- Color Grading ---
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform float saturation : hint_range(0.0, 2.0) = 0.8;
uniform vec4 tint_color : source_color = vec4(0.88, 0.82, 1.0, 1.0);

// --- God Rays ---
uniform float ray_intensity : hint_range(0.0, 1.0) = 0.2;

vec3 adjust_saturation(vec3 color, float sat) {
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luma), color, sat);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 screen_col = texture(screen_texture, uv);
	vec3 color = screen_col.rgb;

	// Direction and distance to sun
	vec2 to_sun = sun_position - uv;
	float dist = length(to_sun);

	// --- Sun Radial Light ---
	float sun_atten = clamp(1.0 - dist / max(sun_radius, 0.01), 0.0, 1.0);
	sun_atten = sun_atten * sun_atten; // quadratic falloff for natural look
	vec3 sun_contrib = sun_color.rgb * sun_atten * sun_intensity;
	// Additive glow + multiplicative warm tint
	color += sun_contrib * 0.18;
	color = mix(color, color * (vec3(1.0) + sun_contrib * 0.4), sun_atten * 0.5);

	// --- Ambient Shadow Fill (cool color in dark areas) ---
	float brightness = luma(color);
	float shadow_factor = clamp(1.0 - brightness, 0.0, 1.0);
	color += ambient_color.rgb * ambient_intensity * shadow_factor * 0.65;

	// --- God Rays (10 samples toward sun, constant for GL Compatibility) ---
	vec2 ray_step = to_sun / 10.0;
	float ray_accum = 0.0;
	float w = 1.0;
	vec2 ruv = uv;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w; w *= 0.88;
	ruv += ray_step; ray_accum += luma(texture(screen_texture, clamp(ruv, vec2(0.001), vec2(0.999))).rgb) * w;
	ray_accum /= 6.0;

	float ray_falloff = clamp(1.0 - dist * 1.5, 0.0, 1.0);
	color += sun_color.rgb * ray_accum * ray_intensity * ray_falloff;

	// --- Saturation ---
	color = adjust_saturation(color, saturation);

	// --- Contrast (S-curve centered at 0.5) ---
	color = ((color - 0.5) * max(contrast, 0.0)) + 0.5;
	color = clamp(color, 0.0, 1.0);

	// --- Color Tint ---
	color *= tint_color.rgb;

	// --- Vignette (heavy, moody darkness at edges) ---
	vec2 vig = (uv - 0.5) * 2.0;
	float vig_dist = dot(vig, vig);
	float vignette_mask = smoothstep(
		1.0 - vignette_smoothness,
		1.0 + vignette_smoothness * 0.5,
		vig_dist * vignette_intensity * 0.5
	);
	color = mix(color, vec3(0.0), vignette_mask);

	COLOR = vec4(color, screen_col.a);
}
