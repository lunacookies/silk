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

typedef u8 b8;
typedef u16 b16;
typedef u32 b32;
typedef u64 b64;

typedef ptrdiff_t smm;
typedef size_t umm;

typedef float f32;
typedef double f64;

typedef f32 __attribute__((ext_vector_type(2))) f32x2;
typedef f32 __attribute__((ext_vector_type(3))) f32x3;
typedef f32 __attribute__((ext_vector_type(4))) f32x4;

#define Breakpoint() (__builtin_debugtrap())
#define Unreachable() Breakpoint()
#define AssertAlways(condition) \
	if (!(condition)) \
	Breakpoint()

#ifdef DEBUG
#define Assert(condition) AssertAlways(condition)
#else
#define Assert(condition) (void)(condition)
#endif

#define Min(x, y) (((x) < (y)) ? (x) : (y))
#define Max(x, y) (((x) > (y)) ? (x) : (y))

#define size_of(T) ((smm)sizeof(T))
#define align_of(T) ((smm)_Alignof(T))

#define ArrayCount(a) (size_of(a) / size_of((a)[0]))

#define SetBitCountU64(x) (__builtin_popcountll(x))

function smm Kibibytes(smm n);
function smm Mebibytes(smm n);

function umm AlignPow2_(umm base, smm align) __attribute__((unused));
function smm AlignPadPow2(umm base, smm align);

function void MemorySet(void *dst, u8 byte, smm n);
function void MemoryZero(void *dst, smm n);
#define MemoryZeroArray(dst, n) (MemoryZero((dst), (n) * size_of(*(dst))))
#define MemoryZeroStruct(dst) (MemoryZeroArray((dst), 1))
