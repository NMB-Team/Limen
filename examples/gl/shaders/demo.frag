#version 330 core

out vec4 outColor;

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uMouse;

void main() {
	vec2 uv = (gl_FragCoord.xy * 2.0 - uResolution.xy) / uResolution.y;
	vec2 mouse = (uMouse * 2.0 - uResolution.xy) / uResolution.y;

	float time = uTime * 0.8;

	vec3 color = 0.35 + 0.35 * cos(vec3(0.0, 2.0, 4.0) + time + uv.x * 2.2 + uv.y * 1.7);

	float vignette = 1.0 - smoothstep(0.3, 1.4, length(uv));

	color *= 0.4 + vignette * 0.6;

	float distanceToMouse = length(uv - mouse);
	float glow = exp(-5.0 * distanceToMouse);

	color += vec3(1.0, 0.65, 0.2) * glow * 0.8;

	float radius = 0.18 + sin(time * 3.0) * 0.02;
	float ring = 1.0 - smoothstep(0.01, 0.025, abs(distanceToMouse - radius));

	color += vec3(1.0, 0.8, 0.45) * ring * 0.6;
	outColor = vec4(color, 1.0);
}