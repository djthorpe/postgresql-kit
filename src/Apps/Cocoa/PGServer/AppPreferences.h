
#import <Cocoa/Cocoa.h>

@interface AppPreferences : NSObject {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSWindow* _preferencesSheet;	
}

// properties
@property BOOL autoStartServer;
@property BOOL autoHideWindow;
@property NSTimeInterval statusRefreshInterval;

// actions
-(IBAction)ibPreferencesStart:(id)sender;
-(IBAction)ibPreferencesEnd:(id)sender;

@end
