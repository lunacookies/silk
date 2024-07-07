@import AppKit;

#define function static

#define Min(x, y) (((x) < (y)) ? (x) : (y))
#define Max(x, y) (((x) > (y)) ? (x) : (y))

@interface MainView : NSView <CALayerDelegate>
@end

@implementation MainView

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.layer = [CALayer layer];
	self.layer.delegate = self;
	self.wantsLayer = YES;
	self.layer.needsDisplayOnBoundsChange = YES;
	return self;
}

- (void)displayLayer:(CALayer *)layer
{
	self.layer.backgroundColor = NSColor.systemPurpleColor.CGColor;
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

	NSScreen *screen = NSScreen.mainScreen;
	NSRect content_rect = CenteredContentRect(NSMakeSize(600, 700), style_mask, screen);

	window = [[NSWindow alloc] initWithContentRect:content_rect
	                                     styleMask:style_mask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO
	                                        screen:screen];
	window.title = @"Silk";

	[window makeKeyAndOrderFront:nil];
	window.contentView = [[MainView alloc] init];

	[NSApp activate];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (void)populateMainMenu
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSMenu *mainMenu = [[NSMenu alloc] init];

	{
		NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:appMenuItem];

		NSMenu *appMenu = [[NSMenu alloc] init];
		appMenuItem.submenu = appMenu;

		NSString *aboutMenuItemTitle = [NSString stringWithFormat:@"About %@", displayName];
		NSMenuItem *aboutMenuItem =
		        [[NSMenuItem alloc] initWithTitle:aboutMenuItemTitle
		                                   action:@selector(orderFrontStandardAboutPanel:)
		                            keyEquivalent:@""];
		[appMenu addItem:aboutMenuItem];

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *servicesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Services"
		                                                          action:nil
		                                                   keyEquivalent:@""];
		[appMenu addItem:servicesMenuItem];

		NSMenu *servicesMenu = [[NSMenu alloc] init];
		servicesMenuItem.submenu = servicesMenu;
		NSApp.servicesMenu = servicesMenu;

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSString *hideMenuItemTitle = [NSString stringWithFormat:@"Hide %@", displayName];
		NSMenuItem *hideMenuItem = [[NSMenuItem alloc] initWithTitle:hideMenuItemTitle
		                                                      action:@selector(hide:)
		                                               keyEquivalent:@"h"];
		[appMenu addItem:hideMenuItem];

		NSMenuItem *hideOthersMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Hide Others"
		                                   action:@selector(hideOtherApplications:)
		                            keyEquivalent:@"h"];
		hideOthersMenuItem.keyEquivalentModifierMask |= NSEventModifierFlagOption;
		[appMenu addItem:hideOthersMenuItem];

		NSMenuItem *showAllMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Show All"
		                                   action:@selector(unhideAllApplications:)
		                            keyEquivalent:@""];
		[appMenu addItem:showAllMenuItem];

		[appMenu addItem:[NSMenuItem separatorItem]];

		NSString *quitMenuItemTitle = [NSString stringWithFormat:@"Quit %@", displayName];
		NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitMenuItemTitle
		                                                      action:@selector(terminate:)
		                                               keyEquivalent:@"q"];
		[appMenu addItem:quitMenuItem];
	}

	{
		NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:fileMenuItem];

		NSMenu *fileMenu = [[NSMenu alloc] init];
		fileMenu.title = @"File";
		fileMenuItem.submenu = fileMenu;

		NSMenuItem *closeMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Close"
		                                   action:@selector(performClose:)
		                            keyEquivalent:@"w"];
		[fileMenu addItem:closeMenuItem];
	}

	{
		NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:viewMenuItem];

		NSMenu *viewMenu = [[NSMenu alloc] init];
		viewMenu.title = @"View";
		viewMenuItem.submenu = viewMenu;

		NSMenuItem *enterFullScreenMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Enter Full Screen"
		                                   action:@selector(toggleFullScreen:)
		                            keyEquivalent:@"f"];
		enterFullScreenMenuItem.keyEquivalentModifierMask |= NSEventModifierFlagControl;
		[viewMenu addItem:enterFullScreenMenuItem];
	}

	{
		NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
		[mainMenu addItem:windowMenuItem];

		NSMenu *windowMenu = [[NSMenu alloc] init];
		windowMenu.title = @"Window";
		windowMenuItem.submenu = windowMenu;

		NSMenuItem *minimizeMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Minimize"
		                                   action:@selector(performMiniaturize:)
		                            keyEquivalent:@"m"];
		[windowMenu addItem:minimizeMenuItem];

		NSMenuItem *zoomMenuItem = [[NSMenuItem alloc] initWithTitle:@"Zoom"
		                                                      action:@selector(performZoom:)
		                                               keyEquivalent:@""];
		[windowMenu addItem:zoomMenuItem];

		[windowMenu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *bringAllToFrontMenuItem =
		        [[NSMenuItem alloc] initWithTitle:@"Bring All to Front"
		                                   action:@selector(arrangeInFront:)
		                            keyEquivalent:@""];
		[windowMenu addItem:bringAllToFrontMenuItem];

		NSApp.windowsMenu = windowMenu;
	}

	NSApp.mainMenu = mainMenu;
}

function NSRect
CenteredContentRect(NSSize content_size, NSWindowStyleMask style_mask, NSScreen *screen)
{
	NSEdgeInsets insets = VisibleScreenFrameEdgeInsets(screen);

	// Ignore horizontal offsets (caused by those heathens who position the Dock on the left or
	// right edge of the screen) to make sure the window is centered horizontally.
	insets.left = 0;
	insets.right = 0;

	NSRect full_screen_frame = {0};
	full_screen_frame.size = screen.frame.size;
	NSRect screen_frame = InsetRect(full_screen_frame, insets);

	NSRect content_rect = {0};
	content_rect.size = content_size;
	NSSize window_size =
	        [NSWindow frameRectForContentRect:content_rect styleMask:style_mask].size;

	NSRect window_rect = {0};
	window_rect.size = window_size;
	window_rect.origin = screen_frame.origin;

	// 1:1 left gap to right gap ratio.
	window_rect.origin.x += (screen_frame.size.width - window_size.width) / 2;

	// 1:2 top gap to bottom gap ratio.
	window_rect.origin.y += (screen_frame.size.height - window_size.height) / 3 * 2;

	return [NSWindow contentRectForFrameRect:window_rect styleMask:style_mask];
}

function NSEdgeInsets
VisibleScreenFrameEdgeInsets(NSScreen *screen)
{
	NSEdgeInsets result = {0};

	NSRect full_screen_frame = screen.frame;
	NSRect visible_screen_frame = screen.visibleFrame;

	result.bottom = visible_screen_frame.origin.y - full_screen_frame.origin.y;
	result.left = visible_screen_frame.origin.x - full_screen_frame.origin.x;

	result.top = (full_screen_frame.origin.y + full_screen_frame.size.height) -
	             (visible_screen_frame.origin.y + visible_screen_frame.size.height);
	result.right = (full_screen_frame.origin.x + full_screen_frame.size.width) -
	               (visible_screen_frame.origin.x + visible_screen_frame.size.width);

	return result;
}

function NSRect
InsetRect(NSRect rect, NSEdgeInsets insets)
{
	NSRect result = rect;

	result.origin.x += insets.left;
	result.size.width -= insets.left;

	result.origin.y += insets.bottom;
	result.size.height -= insets.bottom;

	result.size.width -= insets.right;

	result.size.height -= insets.top;

	return result;
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
