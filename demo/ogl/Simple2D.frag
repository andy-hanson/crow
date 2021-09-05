#version 300 es

#ifdef GL_ES
precision highp float;
#endif

in vec4 colour;
out vec4 fragColour;

void main() {
	fragColour = colour;
}
