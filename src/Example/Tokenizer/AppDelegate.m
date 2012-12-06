
#import "AppDelegate.h"

#import "HostAccessViewController.h"
#import "ConfigurationViewController.h"
#import "NSWindow+ResizeAdditions.h"
#import "ViewController.h"

@implementation AppDelegate

-(id)init {
    self = [super init];
    if (self) {
        _views = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)_addViewController:(ViewController* )viewController {
	// add tab to tab view
	NSTabViewItem* item = [[NSTabViewItem alloc] initWithIdentifier:[viewController identifier]];
	[item setView:[viewController view]];
	[_tabView addTabViewItem:item];
	[_views setObject:viewController forKey:[viewController identifier]];
}

-(void)awakeFromNib {
	[self _addViewController:[[HostAccessViewController alloc] init]];
	[self _addViewController:[[ConfigurationViewController alloc] init]];
	
	// switch toolbar
	NSToolbarItem* toolbarItem = [[[_mainWindow toolbar] visibleItems] objectAtIndex:0];
	[[_mainWindow toolbar] setSelectedItemIdentifier:[toolbarItem itemIdentifier]];
	[self ibToolbarItemClicked:toolbarItem];
}

-(IBAction)ibToolbarItemClicked:(id)sender {
	NSToolbarItem* item = (NSToolbarItem* )sender;
	NSParameterAssert([item isKindOfClass:[NSToolbarItem class]]);
	NSString* identifier = [item itemIdentifier];
	ViewController* viewController = [_views objectForKey:identifier];
	[_tabView selectTabViewItemWithIdentifier:identifier];
	[_mainWindow resizeToSize:[viewController frameSize]];
}

@end
