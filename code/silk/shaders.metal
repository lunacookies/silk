#include <metal_stdlib>
using namespace metal;

struct VertexArguments
{
	float2 resolution;
	float2 position;
	float2 size;
};

struct RasterizerData
{
	float4 position [[position]];
	float4 color;
};

constant float2 positions[] = {
        float2(0, -0.5),
        float2(-0.5, 0.5),
        float2(0.5, 0.5),
};

constant float4 colors[] = {
        float4(1, 0, 0, 1),
        float4(0, 1, 0, 1),
        float4(0, 0, 1, 1),
};

vertex RasterizerData
VertexMain(uint vertex_id [[vertex_id]], constant VertexArguments &arguments)
{
	float2 vertex_position = arguments.position + arguments.size * positions[vertex_id];

	float4 vertex_position_ndc = float4(0, 0, 0, 1);
	vertex_position_ndc.xy = 2 * (vertex_position / arguments.resolution) - 1;
	vertex_position_ndc.y *= -1;

	RasterizerData output = {};
	output.position = vertex_position_ndc;
	output.color = colors[vertex_id];
	return output;
}

fragment float4
FragmentMain(RasterizerData input [[stage_in]])
{
	return input.color;
}
