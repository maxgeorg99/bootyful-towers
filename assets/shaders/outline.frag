// This is a shader that will outline any shape with a red outline

uniform vec2 textureSize;
uniform float outlineWidth = 3.0;
uniform vec4 outlineColor = vec4(1.0, 0.0, 0.0, 1.0); // Red outline

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Sample the current pixel
    vec4 pixelColor = Texel(tex, texture_coords);
    
    // If pixel is completely transparent, check neighbors for non-transparent pixels
    if (pixelColor.a < 0.01) {
        // Define step size for sampling neighboring pixels
        vec2 step = 1.0 / textureSize;
        
        // Check surrounding pixels within the outline width
        bool hasNeighbor = false;
        
        for (float x = -outlineWidth; x <= outlineWidth; x++) {
            for (float y = -outlineWidth; y <= outlineWidth; y++) {
                // Skip checking the current pixel
                if (x == 0 && y == 0) continue;
                
                // Calculate distance from center
                float dist = sqrt(x*x + y*y);
                if (dist > outlineWidth) continue;
                
                // Sample neighbor
                vec4 neighbor = Texel(tex, texture_coords + vec2(x, y) * step);
                
                // If neighbor has content, we're on an edge
                if (neighbor.a > 0.5) {
                    hasNeighbor = true;
                    break;
                }
            }
            if (hasNeighbor) break;
        }
        
        // Return outline color if we're on an edge
        if (hasNeighbor) {
            return outlineColor;
        }
        
        return pixelColor * color;
    }
    
    // For non-transparent pixels, just return the original color
    return pixelColor * color;
}

