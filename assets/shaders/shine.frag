// void mainImage(out vec4 fragColor, in vec2 fragCoord) {
//     vec2 uv = fragCoord / iResolution.xy;
//     float aspect = iResolution.x / iResolution.y;
//     uv.x *= aspect;

//     // TODO: This is just blocking out a "card" to show the effect inside shadertoy
//     float cardWidth = 0.716;
//     float cardHeight = 1.0;
//     vec2 cardSize = vec2(cardWidth, cardHeight) * 0.8;
//     vec2 cardCenter = vec2(0.5 * aspect, 0.5);
//     vec2 cardMin = cardCenter - cardSize * 0.5;
//     vec2 cardMax = cardCenter + cardSize * 0.5;

//     float imageWidth = cardWidth * 0.7;
//     float imageHeight = cardHeight * 0.6;
//     vec2 imageSize = vec2(imageWidth, imageHeight);
//     vec2 imageCenter = cardCenter;
//     vec2 imageMin = imageCenter - imageSize * 0.5;
//     vec2 imageMax = imageCenter + imageSize * 0.5;


//     float borderThickness = 0.05;
//     vec2 innerMin = cardMin + vec2(borderThickness * cardWidth, borderThickness * cardHeight);
//     vec2 innerMax = cardMax - vec2(borderThickness * cardWidth, borderThickness * cardHeight);

//     vec3 baseColor;
//     if (uv.x > cardMin.x && uv.x < cardMax.x && uv.y > cardMin.y && uv.y < cardMax.y) {
//         baseColor = vec3(0.0); // Black border
//         if (uv.x > innerMin.x && uv.x < innerMax.x && uv.y > innerMin.y && uv.y < innerMax.y) {
//             baseColor = vec3(0.7, 0.6, 0.5);
//         }
//         if (uv.x > imageMin.x && uv.x < imageMax.x && uv.y > imageMin.y && uv.y < imageMax.y) {
//             baseColor = vec3(0.9);
//         }
//     } else {
//         baseColor = vec3(0.2);
//     }
//     // TODO: Cut this whole chunk in the actual shader

//     float diagonal = uv.x + uv.y;
//     float speed = 2.0;
//     float bandPosition = mod(diagonal - iTime * speed, 2.0) - 1.0;
//     float bandWidth = 0.2;
//     float shine = smoothstep(-bandWidth, 0.0, bandPosition) * smoothstep(bandWidth, 0.0, bandPosition);

//     // This boosts the effect of the shine on brighter areas of the card
//     float brightness = dot(baseColor, vec3(0.299, 0.587, 0.114));
//     float shineIntensity = 0.8;
//     vec3 shineColor = vec3(1.0, 1.0, 1.2);
//     vec3 finalShine = shine * shineColor * shineIntensity * brightness;

//     // This is the part that masks off where the shine applies, based on some brightness threshold
//     float shineMask = step(0.5, brightness); // This isolates the shine to pixels w/ brightness > 0.5
//     finalShine *= shineMask;

//     fragColor = vec4(baseColor + finalShine, 1.0);
// }

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_intensity = 0.8;
uniform vec2 u_mouse;
uniform float u_preserve_color = 0.7; // New uniform to control color preservation

float easeInSine(float x) {
  return 1 - cos((x * 3.14159) / 2);
}

vec4 effect(vec4 color, Image texture, vec2 texCoords, vec2 screenCoords) {
    vec4 baseColor = Texel(texture, texCoords) * color; // Multiply by vertex color for text

    if (u_mouse.x < 0.0) {
      return baseColor;
    }

    float diagonal = texCoords.x + texCoords.y;
    float speed = 2.0;

    // Add time-based randomness to spacing and positions
    float timeVar1 = sin(u_time * 0.4) * 0.2;
    float timeVar2 = cos(u_time * 0.3) * 0.2;
    float timeVar3 = sin(u_time * 0.5 + 1.5) * 0.2;

    // Calculate three band positions with slightly randomized spacing
    float baseSpacing = 0.67;
    float spacing1 = baseSpacing * (1.0 + timeVar1 * 0.2);
    float spacing2 = baseSpacing * (1.0 + timeVar2 * 0.2);

    float bandPosition1 = mod(diagonal - u_mouse.x * 1.5 + timeVar1, 2.0);
    float bandPosition2 = mod(diagonal - u_mouse.x * 1.5 + spacing1 + timeVar2, 2.0);
    float bandPosition3 = mod(diagonal - u_mouse.x * 1.5 + spacing1 + spacing2 + timeVar3, 2.0);

    float bandWidth = 0.1 + easeInSine(u_mouse.y) * 0.35;
    float bandWidth1 = bandWidth * (1.0 + timeVar1 * 0.15);
    float bandWidth2 = bandWidth * (1.0 + timeVar2 * 0.15);
    float bandWidth3 = bandWidth * (1.0 + timeVar3 * 0.15);

    float shine1 = smoothstep(-bandWidth1, 0.0, bandPosition1) * smoothstep(bandWidth1, 0.0, bandPosition1);
    float shine2 = smoothstep(-bandWidth2, 0.0, bandPosition2) * smoothstep(bandWidth2, 0.0, bandPosition2);
    float shine3 = smoothstep(-bandWidth3, 0.0, bandPosition3) * smoothstep(bandWidth3, 0.0, bandPosition3);

    // Modified shine colors to be less overwhelming
    vec3 shine1color = vec3(sin(u_time + 0) * 0.3 + 0.5, 0.8, 0.9);
    vec3 shine2color = vec3(sin(u_time + 1) * 0.3 + 0.5, 0.8, 0.9);
    vec3 shine3color = vec3(sin(u_time + 2) * 0.3 + 0.5, 0.8, 0.9);

    vec3 shine = shine1 * shine1color + shine2 * shine2color + shine3 * shine3color;

    float brightness = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 finalShine = shine * u_intensity * brightness;

    float shineMask = step(0.2, brightness);
    finalShine *= shineMask;

    // Preserve original color while adding shine
    vec3 finalColor = mix(baseColor.rgb + finalShine, baseColor.rgb, u_preserve_color);

    return vec4(finalColor, baseColor.a);
}

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
  if (u_mouse.x < 0.0) {
    return transform_projection * vertex_position;
  }

  vec2 center = vec2(u_resolution.x / 2.0, u_resolution.y / 2.0);

  float x = vertex_position.x - center.x;
  float y = vertex_position.y - center.y;

  float tiltFactor = 0.005;
  vec2 tiltAngles = vec2(
    (0.5 - u_mouse.y) * tiltFactor,
    (u_mouse.x - 0.5) * tiltFactor
  );

  float z = 0.0;

  float cosX = cos(tiltAngles.x);
  float sinX = sin(tiltAngles.x);
  float y2 = y * cosX - z * sinX;
  float z2 = y * sinX + z * cosX;

  float cosY = cos(tiltAngles.y);
  float sinY = sin(tiltAngles.y);
  float x3 = x * cosY + z2 * sinY;
  float z3 = -x * sinY + z2 * cosY;

  float perspective = 1.0 + z3 * 0.002;
  x3 = x3 * perspective;
  y2 = y2 * perspective;

  vertex_position.x = x3 + center.x;
  vertex_position.y = y2 + center.y;

  return transform_projection * vertex_position;
}
