
#import <Cocoa/Cocoa.h>

@interface FLXPostgresConnectWindowController : NSWindowController {
	NSNetServiceBrowser* netServiceBrowser;
	NSMutableDictionary* settings;
}

@property (retain) NSNetServiceBrowser* netServiceBrowser;
@property (retain) NSMutableDictionary* settings;

// methods
-(void)beginSheetForWindow:(NSWindow* )mainWindow;
-(BOOL)isVisible;

// IBAction
-(IBAction)doEndSheet:(id)sender;

@end
