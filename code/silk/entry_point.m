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
	[self populateMainMenu];

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

@end

int
main(void)
{
	[NSApplication sharedApplication];
	AppDelegate *app_delegate = [[AppDelegate alloc] init];
	NSApp.delegate = app_delegate;
	[NSApp run];
}
