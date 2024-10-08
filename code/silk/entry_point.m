@import AppKit;
@import Darwin;
@import Metal;
@import QuartzCore;

#include "base/base_include.h"
#include "os/os.h"
#include "draw/draw.h"
#include "ui/ui.h"

#include "base/base_include.c"
#include "os/os.c"
#include "draw/draw.c"
#include "ui/ui.c"

typedef struct Arguments Arguments;
struct Arguments
{
	f32x2 resolution;
	u64 rectangles_address;
};

function UI_Signal
B(String string)
{
	UI_Box *b = UI_BoxFromString(string);

	UI_Signal signal = UI_SignalFromBox(b);
	if (UI_Pressed(signal))
	{
		b->background_color = (f32x4){1, 0, 0, 1};
		b->foreground_color = (f32x4){1, 1, 1, 1};
	}
	else if (UI_Hovered(signal))
	{
		b->background_color = (f32x4){0, 0, 1, 1};
		b->foreground_color = (f32x4){1, 1, 1, 1};
	}
	else
	{
		b->background_color = (f32x4){1, 1, 1, 0.5f};
		b->foreground_color = (f32x4){0, 0, 0, 1};
	}

	return signal;
}

function void
BuildUI(Arena *frame_arena, f32 delta_time, f32 scale_factor)
{
	D_BeginFrame();

	f32x2 padding = (f32x2){20, 10};
	UI_BeginFrame(delta_time, scale_factor, padding);

	UI_MakeNextCurrent();
	B(S("panel"));

	local_persist smm count = 0;

	{
		if (UI_Released(B(S("+"))))
		{
			count++;
		}

		if (UI_Released(B(S("-"))) && count > 0)
		{
			count--;
		}

		UI_MakeNextCurrent();
		B(S("foo1"));

		{
			B(S("foo1"));
			B(S("foo2"));
		}

		UI_Pop();

		for (smm i = 0; i < count; i++)
		{
			B(PushStringF(frame_arena, "item%ti", i));
		}
	}

	UI_Pop();

	UI_Draw();
	UI_EndFrame();
}

@interface MainView : NSView
@end

@implementation MainView
{
	id<MTLDevice> device;
	id<MTLCommandQueue> command_queue;
	id<MTLRenderPipelineState> pipeline_state;

	smm current_surface;
	IOSurfaceRef io_surfaces[2];
	id<MTLTexture> textures[2];
	CADisplayLink *display_link;
	b32 just_paused_display_link;
	f64 last_frame_time;

	NSTrackingArea *tracking_area;

	id<MTLBuffer> rectangles_buffer;
	Arena *frame_arena;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.wantsLayer = YES;

	device = MTLCreateSystemDefaultDevice();
	command_queue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];

	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexMain"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentMain"];

	descriptor.colorAttachments[0].blendingEnabled = YES;
	descriptor.colorAttachments[0].destinationRGBBlendFactor =
	        MTLBlendFactorOneMinusSourceAlpha;
	descriptor.colorAttachments[0].destinationAlphaBlendFactor =
	        MTLBlendFactorOneMinusSourceAlpha;
	descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
	descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;

	pipeline_state = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	display_link = [self displayLinkWithTarget:self
	                                  selector:@selector(displayLinkDidRequestFrame)];
	display_link.paused = YES;
	just_paused_display_link = 1;

	[display_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];

	rectangles_buffer = [device newBufferWithLength:(umm)Mebibytes(1)
	                                        options:MTLResourceCPUCacheModeWriteCombined |
	                                                MTLResourceStorageModeShared |
	                                                MTLResourceHazardTrackingModeTracked];

	frame_arena = OS_ArenaAllocDefault();

	return self;
}

- (void)displayLinkDidRequestFrame
{
	self.needsDisplay = YES;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	f64 now = CACurrentMediaTime();
	f64 delta_time = now - last_frame_time;

	if (just_paused_display_link)
	{
		delta_time = 0;
		just_paused_display_link = 0;
	}

	BuildUI(frame_arena, (f32)delta_time, (f32)self.window.backingScaleFactor);

	Assert(IsAligned((umm)rectangles_buffer.contents, align_of(D_Rectangle)));
	AssertAlways((smm)d_state.rectangle_count * size_of(D_Rectangle) <=
	             (smm)rectangles_buffer.length);
	MemoryCopyArray((D_Rectangle *)rectangles_buffer.contents, d_state.rectangles,
	        d_state.rectangle_count);

	display_link.paused = !d_state.wants_frame;
	if (display_link.paused)
	{
		just_paused_display_link = 1;
	}

	id<MTLCommandBuffer> command_buffer = [command_queue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [[MTLRenderPassDescriptor alloc] init];
	descriptor.colorAttachments[0].texture = textures[current_surface];
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [command_buffer renderCommandEncoderWithDescriptor:descriptor];

	Arguments arguments = {0};
	arguments.resolution.x = textures[current_surface].width;
	arguments.resolution.y = textures[current_surface].height;
	arguments.rectangles_address = rectangles_buffer.gpuAddress;

	[encoder setRenderPipelineState:pipeline_state];

	[encoder useResource:rectangles_buffer
	               usage:MTLResourceUsageRead
	              stages:MTLRenderStageVertex | MTLRenderStageFragment];

	[encoder setVertexBytes:&arguments length:sizeof(arguments) atIndex:0];
	[encoder setFragmentBytes:&arguments length:sizeof(arguments) atIndex:0];

	[encoder drawPrimitives:MTLPrimitiveTypeTriangle
	            vertexStart:0
	            vertexCount:6
	          instanceCount:(umm)d_state.rectangle_count];

	[encoder endEncoding];

	[command_buffer commit];
	[command_buffer waitUntilCompleted];

	self.layer.contents = (__bridge id)io_surfaces[current_surface];
	current_surface = (current_surface + 1) % ArrayCount(io_surfaces);

	ArenaClear(frame_arena);
	last_frame_time = now;
}

- (void)mouseEntered:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)mouseExited:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)mouseMoved:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)mouseDown:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)mouseUp:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)scrollWheel:(NSEvent *)event
{
	[self handleEvent:event];
}

- (void)handleEvent:(NSEvent *)ns_event
{
	NSPoint point = ns_event.locationInWindow;
	point.y = self.frame.size.height - point.y;
	point = [self convertPointToBacking:point];

	UI_Event event = {0};

	switch (ns_event.type)
	{
		case NSEventTypeMouseEntered:
			event.kind = UI_EventKind_MouseEntered;
			break;

		case NSEventTypeMouseExited:
			event.kind = UI_EventKind_MouseExited;
			break;

		case NSEventTypeMouseMoved:
			event.kind = UI_EventKind_MouseMoved;
			break;

		case NSEventTypeLeftMouseDown:
			event.kind = UI_EventKind_MouseDown;
			break;

		case NSEventTypeLeftMouseUp:
			event.kind = UI_EventKind_MouseUp;
			break;

		case NSEventTypeScrollWheel:
			event.kind = UI_EventKind_Scroll;
			break;

		default:
			Unreachable();
	}

	event.origin.x = (f32)point.x;
	event.origin.y = (f32)point.y;

	if (event.kind == UI_EventKind_Scroll)
	{
		event.delta.x = (f32)(ns_event.scrollingDeltaX * self.window.backingScaleFactor);
		event.delta.y = (f32)(ns_event.scrollingDeltaY * self.window.backingScaleFactor);
	}

	UI_EnqueueEvent(event);
	display_link.paused = NO;
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];

	[self removeTrackingArea:tracking_area];
	tracking_area =
	        [[NSTrackingArea alloc] initWithRect:self.bounds
	                                     options:NSTrackingActiveAlways | NSTrackingMouseMoved |
	                                             NSTrackingMouseEnteredAndExited
	                                       owner:self
	                                    userInfo:nil];
	[self addTrackingArea:tracking_area];
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self updateIOSurfaces];
	self.needsDisplay = YES;
}

- (void)viewDidChangeBackingProperties
{
	[super viewDidChangeBackingProperties];
	[self updateIOSurfaces];
	self.needsDisplay = YES;
}

- (void)updateIOSurfaces
{
	NSSize size = [self convertSizeToBacking:self.layer.frame.size];

	NSDictionary *properties = @{
		(__bridge NSString *)kIOSurfaceWidth : @(size.width),
		(__bridge NSString *)kIOSurfaceHeight : @(size.height),
		(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		(__bridge NSString *)kIOSurfacePixelFormat : @(kCVPixelFormatType_32BGRA),
	};

	MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.width = (umm)size.width;
	descriptor.height = (umm)size.height;
	descriptor.usage = MTLTextureUsageRenderTarget;
	descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;

	for (smm i = 0; i < ArrayCount(io_surfaces); i++)
	{
		if (io_surfaces[i] != NULL)
		{
			CFRelease(io_surfaces[i]);
		}
		io_surfaces[i] = IOSurfaceCreate((__bridge CFDictionaryRef)properties);
		textures[i] = [device newTextureWithDescriptor:descriptor
		                                     iosurface:io_surfaces[i]
		                                         plane:0];
	}
}

- (void)dealloc
{
	ArenaRelease(frame_arena);
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
{
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self populateMainMenu];

	NSWindowStyleMask style_mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
	                               NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 700)
	                                     styleMask:style_mask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO];

	window.title = @"Silk";
	window.contentView = [[MainView alloc] init];

	[window center];
	[window makeKeyAndOrderFront:nil];
	[NSApp activate];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (void)populateMainMenu
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *display_name = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSMenu *main_menu = [[NSMenu alloc] init];

	{
		NSMenuItem *app_menu_item = [[NSMenuItem alloc] init];
		[main_menu addItem:app_menu_item];

		NSMenu *app_menu = [[NSMenu alloc] init];
		app_menu_item.submenu = app_menu;

		NSString *about_menu_item_title =
		        [NSString stringWithFormat:@"About %@", display_name];
		NSMenuItem *about_menu_item =
		        [[NSMenuItem alloc] initWithTitle:about_menu_item_title
		                                   action:@selector(orderFrontStandardAboutPanel:)
		                            keyEquivalent:@""];
		[app_menu addItem:about_menu_item];

		[app_menu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *services_menu_item = [[NSMenuItem alloc] initWithTitle:@"Services"
		                                                            action:nil
		                                                     keyEquivalent:@""];
		[app_menu addItem:services_menu_item];

		NSMenu *services_menu = [[NSMenu alloc] init];
		services_menu_item.submenu = services_menu;
		NSApp.servicesMenu = services_menu;

		[app_menu addItem:[NSMenuItem separatorItem]];

		NSString *hide_menu_item_title =
		        [NSString stringWithFormat:@"Hide %@", display_name];
		NSMenuItem *hide_menu_item = [[NSMenuItem alloc] initWithTitle:hide_menu_item_title
		                                                        action:@selector(hide:)
		                                                 keyEquivalent:@"h"];
		[app_menu addItem:hide_menu_item];

		NSMenuItem *hide_others_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Hide Others"
		                                   action:@selector(hideOtherApplications:)
		                            keyEquivalent:@"h"];
		hide_others_menu_item.keyEquivalentModifierMask |= NSEventModifierFlagOption;
		[app_menu addItem:hide_others_menu_item];

		NSMenuItem *show_all_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Show All"
		                                   action:@selector(unhideAllApplications:)
		                            keyEquivalent:@""];
		[app_menu addItem:show_all_menu_item];

		[app_menu addItem:[NSMenuItem separatorItem]];

		NSString *quit_menu_item_title =
		        [NSString stringWithFormat:@"Quit %@", display_name];
		NSMenuItem *quit_menu_item = [[NSMenuItem alloc] initWithTitle:quit_menu_item_title
		                                                        action:@selector(terminate:)
		                                                 keyEquivalent:@"q"];
		[app_menu addItem:quit_menu_item];
	}

	{
		NSMenuItem *file_menu_item = [[NSMenuItem alloc] init];
		[main_menu addItem:file_menu_item];

		NSMenu *file_menu = [[NSMenu alloc] init];
		file_menu.title = @"File";
		file_menu_item.submenu = file_menu;

		NSMenuItem *close_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Close"
		                                   action:@selector(performClose:)
		                            keyEquivalent:@"w"];
		[file_menu addItem:close_menu_item];
	}

	{
		NSMenuItem *view_menu_item = [[NSMenuItem alloc] init];
		[main_menu addItem:view_menu_item];

		NSMenu *view_menu = [[NSMenu alloc] init];
		view_menu.title = @"View";
		view_menu_item.submenu = view_menu;

		NSMenuItem *enter_full_screen_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Enter Full Screen"
		                                   action:@selector(toggleFullScreen:)
		                            keyEquivalent:@"f"];
		enter_full_screen_menu_item.keyEquivalentModifierMask |= NSEventModifierFlagControl;
		[view_menu addItem:enter_full_screen_menu_item];
	}

	{
		NSMenuItem *window_menu_item = [[NSMenuItem alloc] init];
		[main_menu addItem:window_menu_item];

		NSMenu *window_menu = [[NSMenu alloc] init];
		window_menu.title = @"Window";
		window_menu_item.submenu = window_menu;

		NSMenuItem *minimize_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Minimize"
		                                   action:@selector(performMiniaturize:)
		                            keyEquivalent:@"m"];
		[window_menu addItem:minimize_menu_item];

		NSMenuItem *zoom_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Zoom"
		                                   action:@selector(performZoom:)
		                            keyEquivalent:@""];
		[window_menu addItem:zoom_menu_item];

		[window_menu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *bring_all_to_front_menu_item =
		        [[NSMenuItem alloc] initWithTitle:@"Bring All to Front"
		                                   action:@selector(arrangeInFront:)
		                            keyEquivalent:@""];
		[window_menu addItem:bring_all_to_front_menu_item];

		NSApp.windowsMenu = window_menu;
	}

	NSApp.mainMenu = main_menu;
}

@end

s32
main(void)
{
	setenv("MTL_SHADER_VALIDATION", "1", 1);
	setenv("MTL_DEBUG_LAYER", "1", 1);
	setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);

	OS_Init();

	[NSApplication sharedApplication];
	AppDelegate *app_delegate = [[AppDelegate alloc] init];
	NSApp.delegate = app_delegate;
	[NSApp run];
}
