typedef struct String String;
struct String
{
	u8 *data;
	smm count;
};

#define S(s) ((String){.data = (u8 *)(s), .count = size_of(s) - 1})
