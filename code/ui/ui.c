typedef struct UI_BoxSlot UI_BoxSlot;
struct UI_BoxSlot
{
	UI_Box *first;
	UI_Box *last;
};

typedef struct UI_EventNode UI_EventNode;
struct UI_EventNode
{
	UI_EventNode *next;
	UI_Event event;
};

typedef struct UI_State UI_State;
struct UI_State
{
	Arena *arena;
	UI_BoxSlot *slots;
	smm slot_count;
	UI_Box *root;
	UI_Box *current;
	b32 next_current;

	Arena *frame_arena;
	UI_EventNode *first_event_node;
	UI_EventNode *last_event_node;

	f32 scale_factor;
	f32x2 padding_target;
	f32x2 padding;
};

global UI_State ui_state;

function void
UI_BeginFrame(f32 delta_time, f32 scale_factor, f32x2 padding)
{
	if (ui_state.arena == 0)
	{
		ui_state.arena = OS_ArenaAllocDefault();
		ui_state.slot_count = 128;
		ui_state.slots = PushArray(ui_state.arena, UI_BoxSlot, ui_state.slot_count);
	}

	if (ui_state.frame_arena == 0)
	{
		ui_state.frame_arena = OS_ArenaAllocDefault();
	}

	ui_state.root = 0;
	ui_state.current = 0;
	ui_state.next_current = 0;

	ui_state.scale_factor = scale_factor;
	ui_state.padding_target = scale_factor * padding;

	f32x2 padding_delta = ui_state.padding_target - ui_state.padding;

	if (All(Abs(padding_delta) < 0.1f))
	{
		ui_state.padding = ui_state.padding_target;
	}
	else
	{
		f32 speed = 40;
		f32 rate = 1 - Pow(2, -speed * delta_time);
		ui_state.padding += rate * padding_delta;
		D_RequestFrame();
	}
}

function void
UI_EndFrame(void)
{
	ArenaClear(ui_state.frame_arena);
	ui_state.first_event_node = 0;
	ui_state.last_event_node = 0;
}

function void
UI_EnqueueEvent(UI_Event event)
{
	UI_EventNode *node = PushStruct(ui_state.frame_arena, UI_EventNode);
	node->event = event;

	if (ui_state.first_event_node == 0)
	{
		ui_state.first_event_node = node;
	}
	else
	{
		ui_state.last_event_node->next = node;
	}
	ui_state.last_event_node = node;
}

function UI_Key
UI_KeyFromString(String string, UI_Key seed)
{
	UI_Key result = seed;

	// https://nnethercote.github.io/2021/12/08/a-brutally-effective-hash-function-in-rust.html
	for (smm i = 0; i < string.count; i++)
	{
		u64 value = (u64)string.data[i];
		result.raw = (RotateLeft(result.raw, 5) ^ value) * 0x517cc1b727220a95;
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
	UI_Box *box = 0;

	Assert(SetBitCount((u64)ui_state.slot_count) == 1);
	smm slot_index = (smm)(key.raw & ((umm)ui_state.slot_count - 1));
	Assert(slot_index >= 0);
	Assert(slot_index < ui_state.slot_count);
	UI_BoxSlot *slot = ui_state.slots + slot_index;

	for (UI_Box *slot_box = slot->first; slot_box != 0; slot_box = slot_box->next_in_slot)
	{
		if (slot_box->key.raw == key.raw)
		{
			box = slot_box;
			box->first = 0;
			box->last = 0;
			box->next = 0;
			box->parent = 0;
			break;
		}
	}

	if (box == 0)
	{
		if (slot->first == 0)
		{
			box = PushStruct(ui_state.arena, UI_Box);
			slot->first = box;
		}
		else
		{
			slot->last->next_in_slot = box;
		}
		slot->last = box;
	}

	box->key = key;
	box->string = string;

	if (ui_state.current != 0)
	{
		box->parent = ui_state.current;
		if (ui_state.current->first == 0)
		{
			ui_state.current->first = box;
		}
		else
		{
			ui_state.current->last->next = box;
		}
		ui_state.current->last = box;
	}

	if (ui_state.root == 0)
	{
		ui_state.root = box;
		ui_state.current = box;
	}

	if (ui_state.next_current)
	{
		ui_state.current = box;
		ui_state.next_current = 0;
	}

	return box;
}

function UI_Signal
UI_SignalFromBox(UI_Box *box)
{
	f32x2 p0 = box->origin;
	f32x2 p1 = box->origin + box->size;

	UI_Signal signal = {0};

	for (UI_EventNode *node = ui_state.first_event_node; node != 0; node = node->next)
	{
		UI_Event *event = &node->event;

		if (event->kind == UI_EventKind_MouseExited)
		{
			signal.flags &= ~UI_SignalFlag_Hovered;
			signal.flags &= ~UI_SignalFlag_Pressed;
			continue;
		}

		b32 in_bounds = All(p0 <= event->origin) && All(event->origin < p1);
		if (!in_bounds)
		{
			continue;
		}

		switch (event->kind)
		{
			case UI_EventKind_MouseEntered:
			case UI_EventKind_MouseMoved:
				signal.flags |= UI_SignalFlag_Hovered;
				break;

			case UI_EventKind_MouseDown:
				signal.flags |= UI_SignalFlag_Hovered;
				signal.flags |= UI_SignalFlag_Pressed;
				break;

			case UI_EventKind_MouseUp:
				signal.flags |= UI_SignalFlag_Hovered;
				signal.flags |= UI_SignalFlag_Released;
				break;

			default:
				Unreachable();
		}
	}

	return signal;
}

function b32
UI_Hovered(UI_Signal signal)
{
	b32 result = signal.flags & UI_SignalFlag_Hovered;
	return result;
}

function b32
UI_Pressed(UI_Signal signal)
{
	b32 result = signal.flags & UI_SignalFlag_Pressed;
	return result;
}

function b32
UI_Released_(UI_Signal signal)
{
	b32 result = signal.flags & UI_SignalFlag_Released;
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

global f32 ui_glyph_width = 10;
global f32 ui_glyph_height = 20;
global f32 ui_glyph_gap = 2;

function f32x2
UI_TextSize(String text)
{
	f32x2 result = 0;
	result.x = text.count * ui_glyph_width + (text.count - 1) * ui_glyph_gap;
	result.y = ui_glyph_height;
	result *= ui_state.scale_factor;
	return result;
}

function void
UI_TextDraw(String text, f32x2 origin, f32x4 color)
{
	f32x2 cursor = origin;
	for (smm i = 0; i < text.count; i++)
	{
		D_Rect(cursor, (f32x2){ui_glyph_width, ui_glyph_height} * ui_state.scale_factor,
		        color);
		cursor.x += (ui_glyph_width + ui_glyph_gap) * ui_state.scale_factor;
	}
}

function void
UI_BoxLayout(UI_Box *box, f32x2 cursor)
{
	box->origin = cursor;
	cursor += ui_state.padding;

	f32x2 min_size = UI_TextSize(box->string);

	for (UI_Box *child = box->first; child != 0; child = child->next)
	{
		UI_BoxLayout(child, cursor);
		min_size = Max(min_size, child->size);
		cursor.y += child->size.y + ui_state.padding.y;
	}

	cursor.x -= ui_state.padding.x;

	box->size.x = ui_state.padding.x * 2 + min_size.x;
	box->size.y = Max(cursor.y - box->origin.y, ui_state.padding.y * 2 + min_size.y);
}

function void
UI_BoxDraw(UI_Box *box)
{
	D_Rect(box->origin, box->size, box->background_color);
	UI_TextDraw(box->string, box->origin + ui_state.padding, box->foreground_color);
	for (UI_Box *child = box->first; child != 0; child = child->next)
	{
		UI_BoxDraw(child);
	}
}

function void
UI_Draw(void)
{
	UI_BoxLayout(ui_state.root, 0);
	UI_BoxDraw(ui_state.root);
}
