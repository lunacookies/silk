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
	UI_Key key;

	f32x2 origin;
	f32x2 size;

	String string;
};

function void UI_BeginFrame(f32 delta_time, f32 scale_factor, f32x2 padding);
function UI_Box *UI_BoxFromString(String string);
function void UI_MakeNextCurrent(void);
function void UI_Pop(void);
function void UI_Draw(void);
