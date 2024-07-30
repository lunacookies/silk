@import AppKit;
@import Darwin;
@import Metal;

#include "base/base_include.h"
#include "os/os.h"

#include "base/base_include.c"
#include "os/os.c"

@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct
{
	f32x2 resolution;
	f32x2 position;
	f32x2 size;
} VertexArguments;

@interface MainView : NSView
@end

@implementation MainView
{
	id<MTLDevice> device;
	id<MTLCommandQueue> command_queue;
	id<MTLRenderPipelineState> pipeline_state;

	IOSurfaceRef io_surface;
	id<MTLTexture> texture;
	f32x2 mouse_location;

	NSTrackingArea *tracking_area;

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

	pipeline_state = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	frame_arena = OS_ArenaAllocDefault();

	return self;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	id<MTLCommandBuffer> command_buffer = [command_queue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [[MTLRenderPassDescriptor alloc] init];
	descriptor.colorAttachments[0].texture = texture;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [command_buffer renderCommandEncoderWithDescriptor:descriptor];

	f32 scale_factor = (f32)self.window.backingScaleFactor;

	VertexArguments arguments = {0};
	arguments.resolution.x = texture.width;
	arguments.resolution.y = texture.height;
	arguments.position = mouse_location * scale_factor;
	arguments.size = (f32x2){100, 100} * scale_factor;

	[encoder setRenderPipelineState:pipeline_state];
	[encoder setVertexBytes:&arguments length:sizeof(arguments) atIndex:0];
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

	[encoder endEncoding];

	[command_buffer commit];
	[command_buffer waitUntilCompleted];

	[self.layer setContentsChanged];

	ArenaClear(frame_arena);
}

- (void)mouseMoved:(NSEvent *)event
{
	NSPoint point = event.locationInWindow;
	point.y = self.frame.size.height - point.y;
	mouse_location.x = (f32)point.x;
	mouse_location.y = (f32)point.y;
	self.needsDisplay = YES;
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];

	[self removeTrackingArea:tracking_area];
	tracking_area =
	        [[NSTrackingArea alloc] initWithRect:self.bounds
	                                     options:NSTrackingActiveAlways | NSTrackingMouseMoved
	                                       owner:self
	                                    userInfo:nil];
	[self addTrackingArea:tracking_area];
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self updateIOSurface];
	self.needsDisplay = YES;
}

- (void)viewDidChangeBackingProperties
{
	[super viewDidChangeBackingProperties];
	[self updateIOSurface];
	self.needsDisplay = YES;
}

- (void)updateIOSurface
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

	if (io_surface != NULL)
	{
		CFRelease(io_surface);
	}

	io_surface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);
	texture = [device newTextureWithDescriptor:descriptor iosurface:io_surface plane:0];

	self.layer.contents = (__bridge id)io_surface;
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
