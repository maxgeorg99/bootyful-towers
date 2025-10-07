uniform Image palette;   // The color palette image (armor-map.png)
uniform vec2 paletteSize; // Size of the palette in pixels
uniform int levelColumn;  // The column index to use from the palette (based on level)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Get the original pixel color from the sprite
    vec4 pixel = Texel(texture, texture_coords);
    
    // If the pixel is fully transparent, don't process it
    if (pixel.a < 0.01) {
        return pixel * color;
    }
    
    // Search for the closest color in the first column of the palette
    float bestMatch = 1000.0;
    int bestRow = 0;
    
    // Loop through each row in the first column to find the source color
    for (int row = 0; row < int(paletteSize.y); row++) {
        // Get the color from the source column (column 0)
        vec4 sourceColor = Texel(palette, vec2(0.5 / paletteSize.x, (float(row) + 0.5) / paletteSize.y));
        
        // Calculate color difference (simple RGB distance)
        float diff = length(sourceColor.rgb - pixel.rgb);
        
        // If this is a better match, remember it
        if (diff < bestMatch) {
            bestMatch = diff;
            bestRow = row;
        }
    }
    
    // Reduce the threshold to make color matching more precise
    // Lower threshold means we only swap colors that very closely match our palette
    if (bestMatch < 0.2) {
        // Calculate exact column position based on levelColumn
        float colX = (float(levelColumn) + 0.5) / paletteSize.x;
        
        // Get the replacement color from the target column
        vec4 targetColor = Texel(palette, vec2(colX, (float(bestRow) + 0.5) / paletteSize.y));
        
        // Enhance the color differences between tiers
        // This will make the difference more noticeable
        targetColor.rgb = mix(pixel.rgb, targetColor.rgb, 0.85);
        
        // Replace the color but keep the original alpha
        return vec4(targetColor.rgb, pixel.a) * color;
    }
    
    // If no match found, return the original color
    return pixel * color;
} 