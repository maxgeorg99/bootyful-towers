// Fragment shader for edge detection outline effect
extern vec2 texture_size;
extern number edge_threshold;
extern number outline_width;
extern number outline_opacity;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 texel_size = outline_width / texture_size;

    // Sobel edge detection kernels
    // Horizontal kernel (Gx)
    mat3 sobel_x = mat3(
        -1.0, 0.0, 1.0,
        -2.0, 0.0, 2.0,
        -1.0, 0.0, 1.0
    );

    // Vertical kernel (Gy)
    mat3 sobel_y = mat3(
        -1.0, -2.0, -1.0,
         0.0,  0.0,  0.0,
         1.0,  2.0,  1.0
    );

    // Sample the 3x3 neighborhood and calculate gradients
    float gx = 0.0;
    float gy = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 sample_coords = texture_coords + vec2(float(x), float(y)) * texel_size;
            vec4 sample_pixel = Texel(texture, sample_coords);

            // Use luminance for edge detection
            float luminance = dot(sample_pixel.rgb, vec3(0.299, 0.587, 0.114)) * sample_pixel.a;

            // Apply Sobel kernels
            gx += luminance * sobel_x[x + 1][y + 1];
            gy += luminance * sobel_y[x + 1][y + 1];
        }
    }

    // Calculate edge magnitude
    float edge_magnitude = sqrt(gx * gx + gy * gy);

    // Get original pixel
    vec4 original_pixel = Texel(texture, texture_coords);

    // If edge is detected, blend with white outline
    if (edge_magnitude > edge_threshold) {
        // Create white outline with controlled opacity
        vec4 outline_color = vec4(1.0, 1.0, 1.0, outline_opacity);

        // Blend original pixel with outline based on edge strength and opacity
        float blend_factor = edge_magnitude * outline_opacity;
        return mix(original_pixel, outline_color, blend_factor) * color;
    }

    return original_pixel * color;
}
