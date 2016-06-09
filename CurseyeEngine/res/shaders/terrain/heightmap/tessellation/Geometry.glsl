#version 430

layout(triangles) in;

layout(triangle_strip, max_vertices = 3) out;

in vec2 texCoordG[];

out vec2 texCoordF;
out vec3 positionF;
out vec3 tangent;

struct Material
{
	sampler2D displacemap;
	float displaceScale;
};

struct Fractal
{
	sampler2D normalmap;
	int scaling;
};

uniform Fractal fractals1[10];
uniform int largeDetailedRange;
uniform mat4 projectionViewMatrix;
uniform vec3 eyePosition;
uniform float scaleY;
uniform float scaleXZ;
uniform sampler2D normalmap;
uniform sampler2D splatmap;
uniform Material sand0;
uniform Material rock0;
uniform Material snow0;
uniform vec4 clipplane;
uniform vec4 frustumPlanes[6];

vec3 Tangent;
vec2 mapCoords0, mapCoords1, mapCoords2;
float displacement0, displacement1, displacement2;
vec4 displace0, displace1, displace2;


void calcTangent()
{	
	vec3 v0 = gl_in[0].gl_Position.xyz;
	vec3 v1 = gl_in[1].gl_Position.xyz;
	vec3 v2 = gl_in[2].gl_Position.xyz;

	// edges of the face/triangle
    vec3 e1 = v1 - v0;
    vec3 e2 = v2 - v0;
	
	vec2 uv0 = texCoordG[0];
	vec2 uv1 = texCoordG[1];
	vec2 uv2 = texCoordG[2];

    vec2 deltaUV1 = uv1 - uv0;
	vec2 deltaUV2 = uv2 - uv0;
	
	float r = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x);
	
	Tangent = normalize((e1 * deltaUV2.y - e2 * deltaUV1.y)*r);
}

void main()
{	
	float dist = (distance(gl_in[0].gl_Position.xyz, eyePosition) + distance(gl_in[1].gl_Position.xyz, eyePosition) + distance(gl_in[0].gl_Position.xyz, eyePosition))/3;
	if (dist < largeDetailedRange){
		calcTangent();
		
		mapCoords0 = (gl_in[0].gl_Position.xz + scaleXZ/2)/scaleXZ;
		mapCoords1 = (gl_in[1].gl_Position.xz + scaleXZ/2)/scaleXZ;
		mapCoords2 = (gl_in[2].gl_Position.xz + scaleXZ/2)/scaleXZ;
		
		float sandBlending0 = texture(splatmap, mapCoords0).b;
		float rockBlending0 = texture(splatmap, mapCoords0).g;
		float snowBlending0 = texture(splatmap, mapCoords0).r;
		
		float sandBlending1 = texture(splatmap, mapCoords1).b;
		float rockBlending1 = texture(splatmap, mapCoords1).g;
		float snowBlending1 = texture(splatmap, mapCoords1).r;
		
		float sandBlending2 = texture(splatmap, mapCoords2).b;
		float rockBlending2 = texture(splatmap, mapCoords2).g;
		float snowBlending2 = texture(splatmap, mapCoords2).r;
		
		float displaceScale = scaleY*0.002;
		
		float displaceSand0 = texture(sand0.displacemap, texCoordG[0]).r * (sand0.displaceScale * displaceScale);
		float displaceRock0 = texture(rock0.displacemap, texCoordG[0]).r * (rock0.displaceScale * displaceScale);
		float displaceSnow0 = texture(snow0.displacemap, texCoordG[0]).r * (snow0.displaceScale * displaceScale);
		
		float displaceSand1 = texture(sand0.displacemap, texCoordG[1]).r * (sand0.displaceScale * displaceScale);
		float displaceRock1 = texture(rock0.displacemap, texCoordG[1]).r * (rock0.displaceScale * displaceScale);
		float displaceSnow1 = texture(snow0.displacemap, texCoordG[1]).r * (snow0.displaceScale * displaceScale);
		
		float displaceSand2 = texture(sand0.displacemap, texCoordG[2]).r * (sand0.displaceScale * displaceScale);
		float displaceRock2 = texture(rock0.displacemap, texCoordG[2]).r * (rock0.displaceScale * displaceScale);
		float displaceSnow2 = texture(snow0.displacemap, texCoordG[2]).r * (snow0.displaceScale * displaceScale);
	
		displacement0 = (sandBlending0 * displaceSand0 + rockBlending0 * displaceRock0 + snowBlending0 * displaceSnow0)*
							(- distance(gl_in[0].gl_Position.xyz, eyePosition)/largeDetailedRange + 1);
		displacement1 = (sandBlending1 * displaceSand1 + rockBlending1 * displaceRock1 + snowBlending1 * displaceSnow1)*
							(- distance(gl_in[1].gl_Position.xyz, eyePosition)/largeDetailedRange + 1);
		displacement2 = (sandBlending2 * displaceSand2 + rockBlending2 * displaceRock2 + snowBlending2 * displaceSnow2)*
							(- distance(gl_in[2].gl_Position.xyz, eyePosition)/largeDetailedRange + 1);
	
		displace0 = vec4(normalize((2*(texture(normalmap,mapCoords0).rbg)-1)
							+	(2*(texture(fractals1[0].normalmap,mapCoords0*fractals1[0].scaling).rbg)-1)
							+	(2*(texture(fractals1[1].normalmap,mapCoords0*fractals1[1].scaling).rbg)-1)
							+	(2*(texture(fractals1[2].normalmap,mapCoords0*fractals1[2].scaling).rbg)-1)) * displacement0,0);
		displace1 = vec4(normalize((2*(texture(normalmap,mapCoords1).rbg)-1)
							+	(2*(texture(fractals1[0].normalmap,mapCoords1*fractals1[0].scaling).rbg)-1)
							+	(2*(texture(fractals1[1].normalmap,mapCoords1*fractals1[1].scaling).rbg)-1)
							+	(2*(texture(fractals1[2].normalmap,mapCoords1*fractals1[2].scaling).rbg)-1)) * displacement1,0);
		displace2 = vec4(normalize((2*(texture(normalmap,mapCoords2).rbg)-1)
							+	(2*(texture(fractals1[0].normalmap,mapCoords2*fractals1[0].scaling).rbg)-1)
							+	(2*(texture(fractals1[1].normalmap,mapCoords2*fractals1[1].scaling).rbg)-1)
							+	(2*(texture(fractals1[2].normalmap,mapCoords2*fractals1[2].scaling).rbg)-1)) * displacement2,0);
	}
	
	vec4 position0 = gl_in[0].gl_Position + displace0;
    gl_Position = projectionViewMatrix * position0;
	gl_ClipDistance[0] = dot(gl_Position ,frustumPlanes[0]);
	gl_ClipDistance[1] = dot(gl_Position ,frustumPlanes[1]);
	gl_ClipDistance[2] = dot(gl_Position ,frustumPlanes[2]);
	gl_ClipDistance[3] = dot(gl_Position ,frustumPlanes[3]);
	gl_ClipDistance[4] = dot(gl_Position ,frustumPlanes[4]);
	gl_ClipDistance[5] = dot(gl_Position ,frustumPlanes[5]);
	gl_ClipDistance[6] = dot(position0 ,clipplane);
	texCoordF = texCoordG[0];
	positionF = (position0).xyz;
	tangent = Tangent;
    EmitVertex();
	
	vec4 position1 = gl_in[1].gl_Position + displace1;
	gl_Position = projectionViewMatrix * position1;
	gl_ClipDistance[0] = dot(gl_Position ,frustumPlanes[0]);
	gl_ClipDistance[1] = dot(gl_Position ,frustumPlanes[1]);
	gl_ClipDistance[2] = dot(gl_Position ,frustumPlanes[2]);
	gl_ClipDistance[3] = dot(gl_Position ,frustumPlanes[3]);
	gl_ClipDistance[4] = dot(gl_Position ,frustumPlanes[4]);
	gl_ClipDistance[5] = dot(gl_Position ,frustumPlanes[5]);
	gl_ClipDistance[6] = dot(position1 ,clipplane);
	texCoordF = texCoordG[1];
	positionF = (position1).xyz;
	tangent = Tangent;
    EmitVertex();

	vec4 position2 = gl_in[2].gl_Position + displace2;
	gl_Position = projectionViewMatrix * position2;
	gl_ClipDistance[0] = dot(gl_Position ,frustumPlanes[0]);
	gl_ClipDistance[1] = dot(gl_Position ,frustumPlanes[1]);
	gl_ClipDistance[2] = dot(gl_Position ,frustumPlanes[2]);
	gl_ClipDistance[3] = dot(gl_Position ,frustumPlanes[3]);
	gl_ClipDistance[4] = dot(gl_Position ,frustumPlanes[4]);
	gl_ClipDistance[5] = dot(gl_Position ,frustumPlanes[5]);
	gl_ClipDistance[6] = dot(position2 ,clipplane);
	texCoordF = texCoordG[2];
	positionF = (position2).xyz;
	tangent = Tangent;
    EmitVertex();
	
    EndPrimitive();
}