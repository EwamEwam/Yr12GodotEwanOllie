shader_type canvas_item;uniform float num_colors : hint_range(2.0, 64.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float time; // Time for wave animation
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02; // Strength of the wave distortion
uniform float wave_frequency : hint_range(0.0, 10.0) = 2.0; // Frequency of the waves
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0; // Speed of the wave animation
uniform vec3 tint_color : source_color = vec3(0.7, 0.9, 1.0); // Blue-green tint for underwater effect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;// 4x4 Bayer matrix for ordered dithering
const float bayer_matrix[16] = float[16](
    0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
    3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);// Quantizes a single color channel
float quantize(float value, float levels) {
    return round(value * levels) / levels;
}// Applies Bayer dithering to a single color channel
float dither_channel(float value, vec2 uv, float levels) {
    ivec2 tex_size = textureSize(screen_texture, 0);
    vec2 pixel_pos = uv * vec2(float(tex_size.x), float(tex_size.y));int bx = int(mod(pixel_pos.x, 4.0));
int by = int(mod(pixel_pos.y, 4.0));
float dither_value = bayer_matrix[by * 4 + bx];

float scaled = value * levels;
float fractional = fract(scaled);
float threshold = (dither_value - 0.5) * dither_strength;

if (fractional > threshold) {
    scaled = ceil(scaled);
} else {
    scaled = floor(scaled);
}

return scaled / levels;}void fragment() {
    // Apply wave distortion to UVs
    vec2 uv = SCREEN_UV;
    float wave_offset_x = sin(uv.y * wave_frequency + time * wave_speed) * wave_amplitude; // Horizontal waves
    float wave_offset_y = sin(uv.x * wave_frequency + time * wave_speed) * wave_amplitude; // Vertical waves
    uv.x += wave_offset_x;
    uv.y += wave_offset_y;// Sample texture with distorted UVs
vec3 col = texture(screen_texture, uv).rgb;

// Apply dithering or quantization
if (dither_strength > 0.0) {
    col.r = dither_channel(col.r, SCREEN_UV, num_colors); // Use original SCREEN_UV for dither pattern
    col.g = dither_channel(col.g, SCREEN_UV, num_colors);
    col.b = dither_channel(col.b, SCREEN_UV, num_colors);
} else {
    col.r = quantize(col.r, num_colors);
    col.g = quantize(col.g, num_colors);
    col.b = quantize(col.b, num_colors);
}

// Apply blue-green tint for underwater effect
col *= tint_color;
COLOR = vec4(col, 1.0);}

