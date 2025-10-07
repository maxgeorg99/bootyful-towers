vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords);
    float average = (pixel.r + pixel.g + pixel.b) / 3.0;
    pixel.r = average;
    pixel.g = average;
    pixel.b = average;
    return pixel * color;
}
