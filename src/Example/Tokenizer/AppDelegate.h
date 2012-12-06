
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface AppDelegate : NSObject {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSTabView* _tabView;
	NSMutableDictionary* _views;
}

// toolbar item
-(IBAction)ibToolbarItemClicked:(id)sender;

@end
