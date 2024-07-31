typedef struct D_Rectangle D_Rectangle;
struct D_Rectangle
{
	f32x2 origin;
	f32x2 size;
	f32x4 fill;
};

typedef struct D_State D_State;
struct D_State
{
	Arena *arena;
	smm arena_frame_start_pos;

	D_Rectangle rectangles[1024];
	smm rectangle_count;
};

global D_State d_state;

function void D_BeginFrame(void);
function void D_Rect(f32x2 origin, f32x2 size, f32x4 fill);
