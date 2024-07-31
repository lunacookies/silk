#include <metal_stdlib>
using namespace metal;

struct VertexArguments
{
	float2 resolution;
};

struct Rectangle
{
	float2 origin;
	float2 size;
	float4 fill;
};

struct RasterizerData
{
	float4 position [[position]];
	uint instance_id;
};

constant float2 positions[] = {
        float2(0, 0),
        float2(1, 0),
        float2(0, 1),
        float2(0, 1),
        float2(1, 1),
        float2(1, 0),
};

vertex RasterizerData
VertexMain(uint vertex_id [[vertex_id]],
        uint instance_id [[instance_id]],
        constant VertexArguments &arguments,
        device const Rectangle *rectangles)
{
	Rectangle rect = rectangles[instance_id];
	float2 vertex_position = rect.origin + rect.size * positions[vertex_id];

	float4 vertex_position_ndc = float4(0, 0, 0, 1);
	vertex_position_ndc.xy = 2 * (vertex_position / arguments.resolution) - 1;
	vertex_position_ndc.y *= -1;

	RasterizerData output = {};
	output.position = vertex_position_ndc;
	output.instance_id = instance_id;
	return output;
}

fragment float4
FragmentMain(RasterizerData input [[stage_in]], device const Rectangle *rectangles)
{
	Rectangle rect = rectangles[input.instance_id];
	float4 result = rect.fill;
	result.rgb *= result.a;
	return result;
}
