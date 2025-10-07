
// card.vert
// LÖVE's default vertex shader uniform variables
extern mat4 transform_projection;

// Custom uniform variables passed from Lua
extern vec2 rotation_angles; // X and Y rotation angles in radians
extern vec2 card_size;       // Width and height of the card
extern float perspective_distance; // Distance for perspective projection (higher = less perspective)

// Default vertex attributes
attribute vec4 lov_Position;
attribute vec2 lov_TexCoord;
attribute vec4 lov_Color;

// Variables passed to the pixel shader
varying vec2 var_TexCoord;
varying vec4 var_Color;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    // Pass original texture coordinates and color to pixel shader
    var_TexCoord = lov_TexCoord;
    var_Color = lov_Color;

    // Normalize coordinates from (0,0)-(width,height) to (-0.5,-0.5)-(0.5,0.5)
    vec2 normalizedPos = (vertex_position.xy / card_size) - 0.5;

    // Start with a 3D position (z=0 for flat card)
    vec3 pos3d = vec3(normalizedPos.x, normalizedPos.y, 0.0);

    // Apply rotations using proper 3D rotation matrices
    float cosX = cos(rotation_angles.x);
    float sinX = sin(rotation_angles.x);
    float cosY = cos(rotation_angles.y);
    float sinY = sin(rotation_angles.y);

    // Apply Y-axis rotation first (left/right tilt)
    vec3 rotatedY = vec3(
        pos3d.x * cosY + pos3d.z * sinY,
        pos3d.y,
        -pos3d.x * sinY + pos3d.z * cosY
    );

    // Then apply X-axis rotation (up/down tilt)
    vec3 finalPos3d = vec3(
        rotatedY.x,
        rotatedY.y * cosX - rotatedY.z * sinX,
        rotatedY.y * sinX + rotatedY.z * cosX
    );

    // Apply perspective projection
    // Move the card away from camera to avoid division by zero
    float z_offset = perspective_distance;
    vec2 projected = finalPos3d.xy / (z_offset + finalPos3d.z);

    // Scale back to original coordinates and re-center
    vec2 finalPos2d = (projected + 0.5) * card_size;

    // Apply model-view-projection matrix
    return transform_projection * vec4(finalPos2d, 0.0, 1.0);
}
