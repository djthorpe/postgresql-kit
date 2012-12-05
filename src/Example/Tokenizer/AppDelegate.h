
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface AppDelegate : NSObject {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSTabView* _tabView;
}

// toolbar item
-(IBAction)ibToolbarItemClicked:(id)sender;

@end
