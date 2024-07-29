#define function static
#define global static
#define local_persist static

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;

typedef ptrdiff_t smm;
typedef size_t umm;

typedef float f32;
typedef double f64;

typedef f32 __attribute__((ext_vector_type(2))) f32x2;
typedef f32 __attribute__((ext_vector_type(3))) f32x3;
typedef f32 __attribute__((ext_vector_type(4))) f32x4;

#define Breakpoint() (__builtin_debugtrap())
#define Assert(condition) \
	if (!(condition)) \
	Breakpoint()

#define Min(x, y) (((x) < (y)) ? (x) : (y))
#define Max(x, y) (((x) > (y)) ? (x) : (y))
