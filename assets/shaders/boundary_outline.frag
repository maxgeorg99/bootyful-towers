// Fragment shader for boundary edge detection outline effect
extern vec2 texture_size;
extern number outline_width;
extern vec4 outline_color;
extern number feather_amount;
extern number scale_factor;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Calculate texel size accounting for scale factor to maintain 1-pixel outline
    vec2 texel_size = (1.0 / texture_size) / scale_factor;

    // Get the current pixel's alpha
    vec4 current_pixel = Texel(texture, texture_coords);
    float current_alpha = current_pixel.a;

    // Only outline pixels that are opaque and have at least one transparent neighbor
    // This ensures we only get the outer edge, not internal edges
    bool is_boundary = false;
    
    if (current_alpha > 0.1) {
        // Current pixel is opaque, check if any neighbor is transparent
        vec2 offsets[4] = vec2[4](
            vec2(0.0, -1.0),  // up
            vec2(0.0, 1.0),   // down
            vec2(-1.0, 0.0),  // left
            vec2(1.0, 0.0)    // right
        );
        
        for (int i = 0; i < 4; i++) {
            vec2 sample_coords = texture_coords + offsets[i] * texel_size;
            vec4 neighbor_pixel = Texel(texture, sample_coords);
            if (neighbor_pixel.a < 0.1) { // Threshold for transparency
                is_boundary = true;
                break;
            }
        }
    }
    // Don't outline transparent pixels - only opaque pixels that border transparency

    // If we're on a boundary, apply the outline color with optional feathering
    if (is_boundary) {
        if (feather_amount > 0.0) {
            // For 1-pixel outline, feathering is simpler
            // Calculate feather factor based on distance from edge
            float feather_factor = 1.0;
            
            // Since we're already on a boundary pixel, we can use a simple feather calculation
            // The feather amount controls how much the outline fades
            if (feather_amount > 0.0) {
                // Simple feathering: reduce opacity based on feather amount
                feather_factor = 1.0 / (1.0 + feather_amount);
            }
            
            // Blend outline color with original pixel based on feather factor
            vec4 feathered_outline = mix(current_pixel, outline_color, feather_factor);
            return feathered_outline * color;
        } else {
            // No feathering, solid outline
            return outline_color * color;
        }
    }

    // Otherwise, return the original pixel
    return current_pixel * color;
}
