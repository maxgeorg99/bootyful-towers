// Uniforms to control the effect
uniform vec2 u_mouse; // Mouse position in screen coordinates
uniform vec2 u_resolution; // Screen resolution
uniform float u_time; // Time for animation
uniform float u_intensity = 0.8; // Intensity of the light effect
uniform float u_speed = 0.5; // Speed of light ray movement

// HSV to RGB conversion function
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  // Sample the texture
  vec4 texColor = Texel(tex, texture_coords);
  
  // Normalize screen coordinates and mouse position
  vec2 uv = screen_coords / u_resolution;
  vec2 mouse = u_mouse / u_resolution;
  
  // Calculate direction from texture coordinates to mouse position
  vec2 direction = mouse - uv;
  float dist = length(direction);
  
  // Create light ray effect
  float ray = 0.0;
  
  // Multiple light beams with different frequencies
  for (int i = 0; i < 5; i++) {
    float freq = 6.0 + float(i) * 3.0;
    float speed = u_speed * (0.7 + float(i) * 0.1);
    
    // Angle-based ray with time variation
    float angle = atan(direction.y, direction.x);
    float beam = sin(angle * freq + u_time * speed) * 0.5 + 0.5;
    
    // Fade based on distance from mouse
    float distFade = smoothstep(0.95, 0.1, dist);
    
    ray += beam * distFade * (0.3 - float(i) * 0.04);
  }
  
  // Dynamic iridescent color based on angle and time
  float hue = atan(direction.y, direction.x) / (2.0 * 3.14159) + 0.5;
  // Modulate hue over time
  hue = fract(hue + u_time * 0.05);
  // Convert HSV to RGB for a rainbow effect
  vec3 dynamicColor = hsv2rgb(vec3(hue, 0.6, 1.0));
  
  // Apply a subtle color shift to the rays
  vec3 rayColor = mix(vec3(1.0, 0.9, 0.7), dynamicColor, 0.7);
  
  // Enhanced parallax effect with depth illusion
  float parallaxStrength = 0.04 * u_intensity;
  
  // Create multiple layers of parallax for added depth
  vec2 parallaxOffset1 = direction * ray * parallaxStrength;
  vec2 parallaxOffset2 = direction * ray * parallaxStrength * 0.7;
  vec2 parallaxOffset3 = direction * ray * parallaxStrength * 0.4;
  
  // Sample texture at different offsets to create layered parallax
  vec4 shiftedColor1 = Texel(tex, texture_coords + parallaxOffset1);
  vec4 shiftedColor2 = Texel(tex, texture_coords + parallaxOffset2);
  vec4 shiftedColor3 = Texel(tex, texture_coords + parallaxOffset3);
  
  // Create a glow effect that pulses with time
  float pulse = (sin(u_time * 0.8) * 0.5 + 0.5) * 0.3 + 0.7;
  float glowStrength = ray * u_intensity * pulse;
  
  // Blend the ray effect with the texture
  vec3 finalColor = mix(texColor.rgb, rayColor, ray * u_intensity * 0.6 * texColor.a);
  
  // Add the layers of parallax for depth
  finalColor += shiftedColor1.rgb * ray * u_intensity * 0.4 * texColor.a;
  finalColor += shiftedColor2.rgb * ray * u_intensity * 0.2 * texColor.a;
  finalColor += shiftedColor3.rgb * ray * u_intensity * 0.1 * texColor.a;
  
  // Add a subtle glow
  finalColor += rayColor * glowStrength * 0.2 * texColor.a;
  
  // Add subtle specular highlights
  float specular = pow(max(0.0, 1.0 - abs(dist * 10.0 - 3.0)), 10.0) * 0.5;
  finalColor += vec3(1.0) * specular * ray * texColor.a;
  
  // Preserve original alpha
  return vec4(finalColor, texColor.a) * color;
}