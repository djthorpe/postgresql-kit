
#import <Cocoa/Cocoa.h>

@interface FLXPostgresConnectWindowController : NSWindowController {
	NSNetServiceBrowser* netServiceBrowser;
	NSMutableArray* settings;
}

@property (retain) NSNetServiceBrowser* netServiceBrowser;
@property (retain) NSMutableArray* settings;

// methods
-(void)beginSheetForWindow:(NSWindow* )mainWindow;
-(BOOL)isVisible;

// IBAction
-(IBAction)doEndSheet:(id)sender;

@end
