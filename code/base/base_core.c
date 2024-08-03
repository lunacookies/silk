function u64
SetBitCount(u64 x)
{
	u64 result = (u64)__builtin_popcountll(x);
	return result;
}

function u64
RotateLeft(u64 x, u64 y)
{
	u64 result = __builtin_rotateleft64(x, y);
	return result;
}

function f32
Max(f32 a, f32 b) __attribute__((overloadable))
{
	f32 result = a > b ? a : b;
	return result;
}

function f32x2
Max(f32x2 a, f32x2 b) __attribute__((overloadable))
{
	f32x2 result = {0};
	result[0] = Max(a[0], b[0]);
	result[1] = Max(a[1], b[1]);
	return result;
}

function f32
Pow(f32 base, f32 exponent)
{
	f32 result = powf(base, exponent);
	return result;
}

function f32x2
Abs(f32x2 v)
{
	f32x2 result = {0};
	result[0] = fabsf(v[0]);
	result[1] = fabsf(v[1]);
	return result;
}

function b32
All(b32x2 v)
{
	b32 result = v[0] && v[1];
	return result;
}

function smm
Kibibytes(smm n)
{
	Assert(n >= 0);
	smm result = n * 1024;
	return result;
}

function smm
Mebibytes(smm n)
{
	smm result = 1024 * Kibibytes(n);
	return result;
}

function umm
AlignPow2_(umm base, smm align)
{
	Assert(align >= 1);
	Assert(SetBitCount((u64)align) == 1);

	umm mask = (umm)align - 1;
	umm result = (base + mask) & ~mask;

	Assert(result >= base);
	return result;
}

function smm
AlignPadPow2(umm base, smm align)
{
	Assert(align >= 1);
	Assert(SetBitCount((u64)align) == 1);

	umm mask = (umm)align - 1;
	smm result = (smm)(-base & mask);

	Assert(result >= 0);
	return result;
}

function b32
IsAligned(umm base, smm align)
{
	Assert(align >= 1);
	Assert(SetBitCount((u64)align) == 1);
	umm mask = (umm)align - 1;
	b32 result = (base & mask) == 0;
	return result;
}

function void
MemoryCopy(void *dst, void *src, smm n)
{
	Assert(n >= 0);
	memmove(dst, src, n);
}

function void
MemorySet(void *dst, u8 byte, smm n)
{
	Assert(n >= 0);
	memset(dst, byte, n);
}

function void
MemoryZero(void *dst, smm n)
{
	Assert(n >= 0);
	MemorySet(dst, 0, n);
}
