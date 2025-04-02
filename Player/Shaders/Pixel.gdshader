shader_type canvas_item;

uniform int pixel_size : hint_range(1, 64) = 4;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Get screen resolution
    vec2 screen_res = vec2(textureSize(SCREEN_TEXTURE, 0));

    // Scale UV to pixel grid
    vec2 pixel_uv = floor(uv * screen_res / float(pixel_size)) * float(pixel_size) / screen_res;

    // Sample pixelated texture
    vec4 color = texture(SCREEN_TEXTURE, pixel_uv);

    COLOR = color;
}
