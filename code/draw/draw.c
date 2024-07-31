function void
D_BeginFrame(void)
{
	Arena *arena = d_state.arena;
	if (arena == 0)
	{
		arena = OS_ArenaAllocDefault();
	}

	ArenaClear(arena);
	MemoryZeroStruct(&d_state);
	d_state.arena = arena;
}

function void
D_RequestFrame(void)
{
	d_state.wants_frame = 1;
}

function void
D_Rect(f32x2 origin, f32x2 size, f32x4 fill)
{
	AssertAlways(d_state.rectangle_count < ArrayCount(d_state.rectangles));
	D_Rectangle *rect = d_state.rectangles + d_state.rectangle_count;
	d_state.rectangle_count++;
	rect->origin = origin;
	rect->size = size;
	rect->fill = fill;
}
