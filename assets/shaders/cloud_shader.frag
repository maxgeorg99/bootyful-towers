uniform float time;        // Total elapsed time
uniform vec3 cloudColor;    // Main cloud color
uniform float cloudSpeed;   // Speed of cloud movement
uniform float cloudDensity; // Density/thickness of clouds
uniform float cloudScale;   // Scale of cloud formations

// Pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Value noise for smoother cloud formations
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Cubic Hermite interpolation for smoother transitions
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Simplified fbm for better pixel art clouds
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // Add multiple layers of noise with different frequencies
    for(int i = 0; i < 5; i++) {
        value += amplitude * noise(st * frequency);
        st = st * 2.0 + vec2(0.7, 0.3);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// Quantize a value to specified number of steps
float quantize(float value, float steps) {
    return floor(value * steps) / steps;
}

// Quantize a vec3 color to specified number of steps
vec3 quantizeColor(vec3 color, float steps) {
    return floor(color * steps) / steps;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Pixelate coordinates to match 640x360 resolution
    float pixelX = 640.0;
    float pixelY = 360.0;
    vec2 pixelCoords = vec2(
        floor(texture_coords.x * pixelX) / pixelX,
        floor(texture_coords.y * pixelY) / pixelY
    );
    
    // Get the original pixel color with pixelated coordinates
    vec4 pixel = Texel(texture, pixelCoords);
    
    // Create cloud coordinates with multi-layered movement (using pixelated coords)
    vec2 cloudCoord = pixelCoords * cloudScale;
    
    // Base cloud layer
    cloudCoord.x += time * cloudSpeed * 0.02;
    float baseCloud = fbm(cloudCoord);
    baseCloud = smoothstep(0.4, 0.8, baseCloud * cloudDensity);
    
    // Second layer - slightly different movement and scale
    vec2 cloudCoord2 = pixelCoords * cloudScale * 1.5;
    cloudCoord2.x += time * cloudSpeed * 0.015;
    cloudCoord2.y -= time * cloudSpeed * 0.004;
    float secondCloud = fbm(cloudCoord2);
    secondCloud = smoothstep(0.5, 0.9, secondCloud * cloudDensity * 0.8);
    
    // Combine layers with reduced opacity
    float cloudStrength = (baseCloud + secondCloud * 0.4) * 0.5; // Only 50% opacity max
    cloudStrength = min(cloudStrength, 0.6); // Cap maximum opacity
    
    // QUANTIZATION: Apply 4-step color quantization for pixel art look
    const float colorSteps = 4.0;
    cloudStrength = quantize(cloudStrength, colorSteps);
    
    // Create transparent clouds 
    vec4 cloudColor4 = vec4(cloudColor, cloudStrength);
    cloudColor4.rgb = quantizeColor(cloudColor4.rgb, colorSteps);
    
    // Blend with original pixel using alpha blending
    // Keep the original pixel mostly visible
    vec4 finalColor = vec4(
        mix(pixel.rgb, cloudColor4.rgb, cloudStrength * 0.7),
        pixel.a
    );
    
    return finalColor * color;
} 