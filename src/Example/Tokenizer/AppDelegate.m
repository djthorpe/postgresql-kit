
#import "AppDelegate.h"

#import "HostAccessViewController.h"
#import "ConfigurationViewController.h"

@implementation AppDelegate

-(void)_resizeWindowForContentSize:(NSSize) size {
    NSRect windowFrame = [NSWindow contentRectForFrameRect:[_mainWindow frame] styleMask:[_mainWindow styleMask]];
    NSRect newWindowFrame = [NSWindow frameRectForContentRect:
							 NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) - size.height, size.width, size.height )
													styleMask:[_mainWindow styleMask]];
    [_mainWindow setFrame:newWindowFrame display:YES animate:[_mainWindow isVisible]];
}

-(void)awakeFromNib {
	// load in additional views
	NSViewController* hostAccessView = [[HostAccessViewController alloc] init];
	NSViewController* configurationView = [[ConfigurationViewController alloc] init];
	
	// add tab to tab view
	NSTabViewItem* item = [[NSTabViewItem alloc] initWithIdentifier:@"hostaccess"];
	[item setView:[hostAccessView view]];
	[_tabView addTabViewItem:item];

	// add tab to tab view
	NSTabViewItem* item2 = [[NSTabViewItem alloc] initWithIdentifier:@"configuration"];
	[item2 setView:[configurationView view]];
	[_tabView addTabViewItem:item2];


}

-(IBAction)ibToolbarItemClicked:(id)sender {
	NSToolbarItem* item = (NSToolbarItem* )sender;
	NSParameterAssert([item isKindOfClass:[NSToolbarItem class]]);
	NSString* identifier = [item itemIdentifier];
	NSLog(@"switching to '%@'",identifier);
	[_tabView selectTabViewItemWithIdentifier:identifier];
	
	NSView* selectedView = [[_tabView selectedTabViewItem] view];
	[self _resizeWindowForContentSize:([selectedView frame].size)];
	
}

@end
