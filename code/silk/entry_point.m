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
