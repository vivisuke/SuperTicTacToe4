shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 center;
uniform float force;
uniform float size;
uniform float tichness;

void fragment() {
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 scaledUV = ( SCREEN_UV - vec2(0.5, 0.0) ) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
	float mask = (1.0 - smoothstep(size-0.1, size, length(scaledUV - center))) *
					smoothstep(size-tichness - 0.1, size-tichness, length(scaledUV - center));
	vec2 disp = normalize(scaledUV - center) * force * mask;
	//COLOR = vec4(SCREEN_UV - disp, 0.0, 1.0);
	//COLOR = texture(screen_texture, SCREEN_UV - disp);
	COLOR = textureLod(screen_texture, SCREEN_UV - disp, 0.0);
	//COLOR.rgb = vec3(mask);
	
	//COLOR = vec4(UV, 0.0, 1.0);
	//COLOR = texture(TEXTURE, UV - vec2(0.5, 0));

}
