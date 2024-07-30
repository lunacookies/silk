function void
OS_Init(void)
{
	void *block = OS_Reserve(size_of(OS_HardwareInfo));
	AssertAlways(block);
	os_hardware_info = block;
	AssertAlways(OS_Commit(os_hardware_info, size_of(OS_HardwareInfo)));

	{
		s32 value = 0;
		umm size =(umm) size_of(s32);
		s32 code = sysctlbyname("hw.pagesize", &value, &size, NULL, 0);
		AssertAlways(code == 0);
		AssertAlways(size ==(umm) size_of(s32));

		AssertAlways(value >= 1);
		AssertAlways(SetBitCountU64((u64)value) == 1);
		os_hardware_info->page_size = value;
	}

	AssertAlways(OS_ProtectMemory(os_hardware_info, size_of(OS_HardwareInfo), OS_MemoryProtectionFlag_Read));
}

function void *
OS_Reserve(smm size)
{
	Assert(size >= 1);

	mach_port_t task = mach_task_self();
	void *result = 0;

	kern_return_t kr = vm_allocate(task, (vm_address_t *)&result, (vm_size_t)size, VM_FLAGS_ANYWHERE);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	kr = vm_protect(task, (vm_address_t)result, (vm_size_t)size, 0, VM_PROT_NONE);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	return result;
}

function b32
OS_Commit(void *ptr, smm size)
{
	Assert(size >= 1);

	mach_port_t task = mach_task_self();

	vm_prot_t prot = VM_PROT_READ | VM_PROT_WRITE;
	kern_return_t kr = vm_protect(task, (vm_address_t)ptr, (vm_size_t)size, 0, prot);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	return 1;
}

function b32
OS_Decommit(void *ptr, smm size)
{
	Assert(size >= 1);

	mach_port_t task = mach_task_self();

	kern_return_t kr = vm_protect(task, (vm_address_t)ptr, (vm_size_t)size, 0, VM_PROT_NONE);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	kr = vm_behavior_set(task, (vm_address_t)ptr, (vm_size_t)size, VM_BEHAVIOR_REUSABLE);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	return 1;
}

function b32
OS_Release(void *ptr, smm size)
{
	Assert(size >= 1);

	mach_port_t task = mach_task_self();

	kern_return_t kr = vm_deallocate(task, (vm_address_t)ptr, (vm_size_t)size);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	return 1;
}

function b32
OS_ProtectMemory(void *ptr, smm size, OS_MemoryProtectionFlags flags)
{
	Assert(size >= 1);

	mach_port_t task = mach_task_self();

vm_prot_t prot = VM_PROT_NONE;

	if (flags & OS_MemoryProtectionFlag_Read)
	{
		prot |= VM_PROT_READ;
	}

	if (flags & OS_MemoryProtectionFlag_Write)
	{
		prot |= VM_PROT_WRITE;
	}

	kern_return_t kr = vm_protect(task, (vm_address_t)ptr, (vm_size_t)size, 0, prot);
	if (kr != KERN_SUCCESS)
	{
		return 0;
	}

	return 1;
}

global void *page_allocator_token = 0;

function void *
OS_PageAllocatorProc(void *allocator_data, void *ptr, smm size, PageAllocatorOperation operation)
{
	Assert(allocator_data == page_allocator_token);

	void *result = 0;

	switch (operation)
	{
		case PageAllocatorOperation_Reserve:
			result = OS_Reserve(size);
			AssertAlways(result != 0);
			break;

		case PageAllocatorOperation_Commit:
			AssertAlways(OS_Commit(ptr, size));
			break;

		case PageAllocatorOperation_Decommit:
			AssertAlways(OS_Decommit(ptr, size));
			break;

		case PageAllocatorOperation_Release:
			AssertAlways(OS_Release(ptr, size));
			break;

		case PageAllocatorOperation_QueryAlign:
			result = (void *)(os_hardware_info->page_size);
			break;

		default: Unreachable();
	}

	return result;
}

function Arena *
OS_ArenaAllocDefault(void)
{
	Arena *result = OS_ArenaAlloc(Mebibytes(128), Kibibytes(64));
	return result;
}

function Arena *
OS_ArenaAlloc(smm reserve_size, smm commit_increment)
{
	PageAllocator allocator = {0};
	allocator.data = page_allocator_token;
	allocator.proc = OS_PageAllocatorProc;

	Arena *result = ArenaAlloc(allocator, reserve_size, commit_increment);
	return result;
}
