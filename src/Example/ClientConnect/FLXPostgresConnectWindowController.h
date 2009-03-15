
#import <Cocoa/Cocoa.h>

@interface FLXPostgresConnectWindowController : NSWindowController {
	NSNetServiceBrowser* netServiceBrowser;

	// IBOutlets
	IBOutlet NSArrayController* settings;
	IBOutlet NSButton* ibAdvancedSettingsButton;
	IBOutlet NSView* ibAdvancedSettingsView;	
}

@property (retain) NSNetServiceBrowser* netServiceBrowser;

// methods
-(void)beginSheetForWindow:(NSWindow* )mainWindow;
-(BOOL)isVisible;

// IBAction
-(IBAction)doEndSheet:(id)sender;
-(IBAction)doAdvancedSettings:(id)sender;

@end
