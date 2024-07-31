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
	Assert(SetBitCountU64((u64)align) == 1);

	umm mask = (umm)align - 1;
	umm result = (base + mask) & ~mask;

	Assert(result >= base);
	return result;
}

function smm
AlignPadPow2(umm base, smm align)
{
	Assert(align >= 1);
	Assert(SetBitCountU64((u64)align) == 1);

	umm mask = (umm)align - 1;
	smm result = (smm)(-base & mask);

	Assert(result >= 0);
	return result;
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
