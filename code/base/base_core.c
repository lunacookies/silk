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
