@import AppKit;

@interface MainView : NSView
@end

@implementation MainView

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[NSColor.systemPurpleColor setFill];
	NSRectFill(self.bounds);
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
	NSSize window_size = NSMakeSize(500, 400);

	NSScreen *screen = NSScreen.mainScreen;
	NSRect screen_frame = screen.visibleFrame;

	NSRect window_rect = {0};
	window_rect.size = window_size;
	window_rect.origin = screen_frame.origin;
	window_rect.origin.x += (screen_frame.size.width - window_size.width) / 2;
	window_rect.origin.y += (screen_frame.size.height - window_size.height) / 3 * 2;

	NSWindowStyleMask style_mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
	                               NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

	NSRect window_content_rect = [NSWindow contentRectForFrameRect:window_rect
	                                                     styleMask:style_mask];

	window = [[NSWindow alloc] initWithContentRect:window_content_rect
	                                     styleMask:style_mask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO
	                                        screen:screen];

	[window makeKeyAndOrderFront:nil];
	window.contentView = [[MainView alloc] init];

	[NSApp activate];
}

@end

int
main(void)
{
	[NSApplication sharedApplication];
	AppDelegate *app_delegate = [[AppDelegate alloc] init];
	NSApp.delegate = app_delegate;
	[NSApp run];
}
