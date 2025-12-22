#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

out vec4 finalColor;

void main() {
    // Get the grayscale intensity value from the texture
    float intensity = texture(texture0, fragTexCoord).r;

    // Map intensity to classic heatmap colors (blue -> cyan -> green -> yellow -> red)
    vec3 color;

    if (intensity < 0.05) {
        // Very dark (almost black) to dark blue
        color = mix(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.5), intensity * 20.0);
    } else if (intensity < 0.2) {
        // Dark blue to blue
        color = mix(vec3(0.0, 0.0, 0.5), vec3(0.0, 0.0, 1.0), (intensity - 0.05) / 0.15);
    } else if (intensity < 0.4) {
        // Blue to cyan
        color = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), (intensity - 0.2) / 0.2);
    } else if (intensity < 0.6) {
        // Cyan to green
        color = mix(vec3(0.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0), (intensity - 0.4) / 0.2);
    } else if (intensity < 0.8) {
        // Green to yellow
        color = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (intensity - 0.6) / 0.2);
    } else {
        // Yellow to red
        color = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (intensity - 0.8) / 0.2);
    }

    // If intensity is 0, make it transparent (black background)
    float alpha = intensity > 0.0 ? 1.0 : 0.0;

    finalColor = vec4(color, alpha);
}