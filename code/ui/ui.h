typedef struct UI_Key UI_Key;
struct UI_Key
{
	u64 raw;
};

typedef struct UI_Box UI_Box;
struct UI_Box
{
	UI_Box *first;
	UI_Box *last;
	UI_Box *next;
	UI_Box *parent;
	UI_Box *next_in_slot;
	UI_Box *prev_in_slot;
	UI_Key key;

	smm last_update_frame_index;
	b32 first_frame;

	f32x4 background_color;
	f32x4 foreground_color;

	f32x2 origin;
	f32x2 origin_absolute;
	f32x2 size;
	f32x2 child_offset;

	f32x2 origin_target;
	f32x2 size_target;

	b32 hovered;
	b32 pressed;

	String string;
};

typedef enum
{
	UI_EventKind_Nil,
	UI_EventKind_MouseEntered,
	UI_EventKind_MouseExited,
	UI_EventKind_MouseMoved,
	UI_EventKind_MouseDown,
	UI_EventKind_MouseUp,
	UI_EventKind_Scroll,
	UI_EventKind__Count,
} UI_EventKind;

typedef struct UI_Event UI_Event;
struct UI_Event
{
	UI_EventKind kind;
	f32x2 origin;
	f32x2 delta;
};

typedef u32 UI_SignalFlags;
global read_only UI_SignalFlags UI_SignalFlag_Hovered = 1 << 0;
global read_only UI_SignalFlags UI_SignalFlag_Pressed = 1 << 1;
global read_only UI_SignalFlags UI_SignalFlag_Released = 1 << 2;

typedef struct UI_Signal UI_Signal;
struct UI_Signal
{
	UI_SignalFlags flags;
};

function void UI_BeginFrame(f32 delta_time, f32 scale_factor, f32x2 padding);
function void UI_EndFrame(void);
function void UI_EnqueueEvent(UI_Event event);
function UI_Box *UI_BoxFromString(String string);
function UI_Signal UI_SignalFromBox(UI_Box *box);
function b32 UI_Hovered(UI_Signal signal);
function b32 UI_Pressed(UI_Signal signal);
function b32 UI_Released(UI_Signal signal);
function void UI_MakeNextCurrent(void);
function void UI_Pop(void);
function void UI_Draw(void);
