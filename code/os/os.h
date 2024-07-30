function void OS_Init(void);

typedef struct OS_HardwareInfo OS_HardwareInfo;
struct OS_HardwareInfo
{
	smm page_size;
};

global OS_HardwareInfo *os_hardware_info = 0;

function void *OS_Reserve(smm size);
function b32 OS_Commit(void *ptr, smm size);
function b32 OS_Decommit(void *ptr, smm size);
function b32 OS_Release(void *ptr, smm size);

typedef u32 OS_MemoryProtectionFlags;
enum
{
	OS_MemoryProtectionFlag_Read = 1 << 0,
	OS_MemoryProtectionFlag_Write = 1 << 1,
};

function b32 OS_ProtectMemory(void *ptr, smm size, OS_MemoryProtectionFlags flags);

function Arena *OS_ArenaAllocDefault(void);
function Arena *OS_ArenaAlloc(smm reserve_size, smm commit_increment);
