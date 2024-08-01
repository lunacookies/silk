typedef struct String String;
struct String
{
	u8 *data;
	smm count;
};

#define S(s) ((String){.data = (u8 *)(s), .count = size_of(s) - 1})
#define SF(s) (int)(s).count, (s).data

function String PushStringFV(Arena *arena, char *fmt, va_list ap);
function String PushStringF(Arena *arena, char *fmt, ...);
