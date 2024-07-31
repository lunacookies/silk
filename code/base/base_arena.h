typedef enum
{
	PageAllocatorOperation_Nil,
	PageAllocatorOperation_Reserve,
	PageAllocatorOperation_Commit,
	PageAllocatorOperation_Decommit,
	PageAllocatorOperation_Release,
	PageAllocatorOperation_QueryAlign,
	PageAllocatorOperation__Count,
} PageAllocatorOperation;

typedef void *(*PageAllocatorProc)(
        void *allocator_data, void *ptr, smm size, PageAllocatorOperation operation);

typedef struct PageAllocator PageAllocator;
struct PageAllocator
{
	void *data;
	PageAllocatorProc proc;
};

function void *PageAllocatorReserve(PageAllocator allocator, smm size);
function void PageAllocatorCommit(PageAllocator allocator, void *ptr, smm size);
function void PageAllocatorDecommit_(PageAllocator allocator, void *ptr, smm size)
        __attribute__((unused));
function void PageAllocatorRelease(PageAllocator allocator, void *ptr, smm size);
function smm PageAllocatorAlign(PageAllocator allocator);

typedef struct Arena Arena;
struct Arena
{
	u8 *ptr;
	smm reserved;
	smm committed;
	smm used;
	smm used_header;
	smm commit_increment;
	PageAllocator allocator;
};

function Arena *ArenaAlloc(PageAllocator allocator, smm reserve_size, smm commit_increment);
function void ArenaRelease(Arena *arena);
function void ArenaClear(Arena *arena);
function void *ArenaPush(Arena *arena, smm size, smm align);

#define PushArray(arena, T, count) (ArenaPush((arena), size_of(T) * (count), align_of(T)))
#define PushStruct(arena, T) (PushArray((arena), T, 1))
