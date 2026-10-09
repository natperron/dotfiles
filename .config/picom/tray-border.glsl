#version 330

// Draws a fixed-colour rounded border inside the window, regardless of focus.
// Used for stalonetray, which i3 can't give a per-window border colour.

in vec2 texcoord;
uniform sampler2D tex;
uniform float corner_radius;

vec4 default_post_processing(vec4 c);

const vec4 border_color = vec4(0x62 / 255.0, 0x72 / 255.0, 0xa4 / 255.0, 1.0); // #6272a4
const float thickness = 1.0;

vec4 window_shader()
{
    vec2 tex_size = textureSize(tex, 0);
    vec4 c = texture2D(tex, texcoord / tex_size, 0);

    // Signed distance to the rounded window outline (negative inside)
    vec2 center = (tex_size - 1) / 2;
    vec2 q = abs(texcoord - center) - (center - corner_radius);
    float d = length(max(q, 0)) + min(max(q.x, q.y), 0) - corner_radius;

    // Anti-aliased border band, then clip outside the outline
    c = mix(c, border_color, clamp(d + thickness + 0.5, 0, 1));
    c *= 1 - clamp(d + 0.5, 0, 1);
    return default_post_processing(c);
}
