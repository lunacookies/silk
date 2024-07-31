typedef struct UI_State UI_State;
struct UI_State
{
	Arena *arena;
	UI_Box *root;
	UI_Box *current;
	b32 next_current;
	f32 scale_factor;
};

global UI_State ui_state;

function void
UI_BeginFrame(f32 scale_factor)
{
	Arena *arena = ui_state.arena;
	if (arena == 0)
	{
		arena = OS_ArenaAllocDefault();
	}

	ArenaClear(arena);
	MemoryZeroStruct(&ui_state);
	ui_state.arena = arena;

	ui_state.scale_factor = scale_factor;
}

function UI_Key
UI_KeyFromString(String string, UI_Key seed)
{
	UI_Key result = seed;

	// https://nnethercote.github.io/2021/12/08/a-brutally-effective-hash-function-in-rust.html
	for (smm i = 0; i < string.count; i++)
	{
		u64 value = (u64)string.data[i];
		result.raw = (RotateLeft64(result.raw, 5) ^ value) * 0x517cc1b727220a95;
	}

	return result;
}

function UI_Box *
UI_BoxFromString(String string)
{
	UI_Key seed = {0};
	if (ui_state.current != 0)
	{
		seed = ui_state.current->key;
	}

	UI_Key key = UI_KeyFromString(string, seed);
	UI_Box *result = PushStruct(ui_state.arena, UI_Box);
	result->key = key;

	if (ui_state.current != 0)
	{
		result->parent = ui_state.current;
		if (ui_state.current->first == 0)
		{
			ui_state.current->first = result;
		}
		else
		{
			ui_state.current->last->next = result;
		}
		ui_state.current->last = result;
	}

	if (ui_state.root == 0)
	{
		ui_state.root = result;
		ui_state.current = result;
	}

	if (ui_state.next_current)
	{
		ui_state.current = result;
		ui_state.next_current = 0;
	}

	return result;
}

function void
UI_MakeNextCurrent(void)
{
	ui_state.next_current = 1;
}

function void
UI_Pop(void)
{
	ui_state.current = ui_state.current->parent;
}

function void
UI_BoxLayout(UI_Box *box, f32x2 *cursor)
{
	box->origin = *cursor;

	f32x2 padding = (f32x2){50, 25} * ui_state.scale_factor;
	*cursor += padding;

	f32 widest = 0;
	for (UI_Box *child = box->first; child != 0; child = child->next)
	{
		UI_BoxLayout(child, cursor);
		widest = Max(widest, child->size.x);
		cursor->y += padding.y;
	}

	cursor->x -= padding.x;

	box->size.x = padding.x * 2 + widest;
	box->size.y = cursor->y - box->origin.y;
}

function void
UI_BoxDraw(UI_Box *box)
{
	D_Rect(box->origin, box->size, (f32x4){1, 1, 1, 0.4f});
	for (UI_Box *child = box->first; child != 0; child = child->next)
	{
		UI_BoxDraw(child);
	}
}

function void
UI_Draw(void)
{
	f32x2 cursor = 0;
	UI_BoxLayout(ui_state.root, &cursor);
	UI_BoxDraw(ui_state.root);
}
