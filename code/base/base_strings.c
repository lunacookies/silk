function String
PushStringFV(Arena *arena, char *fmt, va_list ap)
{
	va_list ap2;
	va_copy(ap2, ap);
	String result = {0};
	result.count = vsnprintf(0, 0, fmt, ap2);
	smm allocation_size = result.count + 1;
	result.data = PushArray(arena, u8, allocation_size);
	smm bytes_written = vsnprintf((char *)result.data, allocation_size, fmt, ap) + 1;
	Assert(bytes_written == allocation_size);
	va_end(ap2);
	return result;
}

function String
PushStringF(Arena *arena, char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	String result = PushStringFV(arena, fmt, ap);
	va_end(ap);
	return result;
}
