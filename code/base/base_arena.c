function void *
PageAllocatorReserve(PageAllocator allocator, smm size)
{
	Assert(size >= 0);
	void *result = allocator.proc(allocator.data, 0, size, PageAllocatorOperation_Reserve);
	Assert(AlignPadPow2((umm)result, PageAllocatorAlign(allocator)) == 0);
	return result;
}

function void
PageAllocatorCommit(PageAllocator allocator, void *ptr, smm size)
{
	Assert(size >= 0);
	Assert(AlignPadPow2((umm)ptr, PageAllocatorAlign(allocator)) == 0);
	void *p = allocator.proc(allocator.data, ptr, size, PageAllocatorOperation_Commit);
	Assert(p == 0);
}

function void
PageAllocatorDecommit_(PageAllocator allocator, void *ptr, smm size)
{
	Assert(size >= 0);
	Assert(AlignPadPow2((umm)ptr, PageAllocatorAlign(allocator)) == 0);
	void *p = allocator.proc(allocator.data, ptr, size, PageAllocatorOperation_Decommit);
	Assert(p == 0);
}

function void
PageAllocatorRelease(PageAllocator allocator, void *ptr, smm size)
{
	Assert(size >= 0);
	Assert(AlignPadPow2((umm)ptr, PageAllocatorAlign(allocator)) == 0);
	void *p = allocator.proc(allocator.data, ptr, size, PageAllocatorOperation_Release);
	Assert(p == 0);
}

function smm
PageAllocatorAlign(PageAllocator allocator)
{
	void *result_raw = allocator.proc(allocator.data, 0, 0, PageAllocatorOperation_QueryAlign);
	smm result = (smm)result_raw;
	Assert(result >= 1);
	Assert(SetBitCount((u64)result) == 1);
	return result;
}

function Arena *
ArenaAlloc(PageAllocator allocator, smm initial_reserve_size, smm initial_commit_increment)
{
	Assert(initial_reserve_size > 0);
	Assert(initial_commit_increment >= size_of(Arena) + align_of(Arena));
	Assert(initial_reserve_size >= initial_commit_increment);
	Assert(initial_reserve_size % initial_commit_increment == 0);

	smm allocator_align = PageAllocatorAlign(allocator);
	Assert(AlignPadPow2((umm)initial_reserve_size, allocator_align) == 0);
	Assert(AlignPadPow2((umm)initial_commit_increment, allocator_align) == 0);

	u8 *ptr = PageAllocatorReserve(allocator, initial_reserve_size);
	PageAllocatorCommit(allocator, ptr, initial_commit_increment);

	smm padding = AlignPadPow2((umm)ptr, align_of(Arena));
	Arena *result = (Arena *)(ptr + padding);
	result->ptr = ptr;
	result->reserved = initial_reserve_size;
	result->committed = initial_commit_increment;
	result->used = padding + size_of(Arena);
	result->used_header = result->used;
	result->commit_increment = initial_commit_increment;
	result->allocator = allocator;
	return result;
}

function void
ArenaRelease(Arena *arena)
{
	PageAllocatorRelease(arena->allocator, arena->ptr, arena->reserved);
}

function void
ArenaClear(Arena *arena)
{
	MemoryZero(arena->ptr + arena->used_header, arena->used - arena->used_header);
	arena->used = arena->used_header;
}

function void *
ArenaPush(Arena *arena, smm size, smm align)
{
	Assert(size >= 0);
	Assert(align >= 1);
	Assert(SetBitCount((u64)align) == 1);

	u8 *ptr = arena->ptr + arena->used;
	smm padding = AlignPadPow2((umm)ptr, align);
	smm needed_space = size + padding;

	smm remaining_reserved_space = arena->reserved - arena->used;
	smm remaining_committed_space = arena->committed - arena->used;

	AssertAlways(remaining_reserved_space >= needed_space);

	if (remaining_committed_space < needed_space)
	{
		// Round up to the next multiple of the commit increment.
		smm commit_bytes_needed = (needed_space + arena->commit_increment - 1) /
		                          arena->commit_increment * arena->commit_increment;
		PageAllocatorCommit(
		        arena->allocator, arena->ptr + arena->committed, commit_bytes_needed);
		arena->committed += commit_bytes_needed;
	}

	arena->used += padding;
	void *result = arena->ptr + arena->used;
	arena->used += size;
	return result;
}
