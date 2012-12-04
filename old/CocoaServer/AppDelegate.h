
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    // IBOutlets
	NSWindow* ibWindow;
	NSTextView* ibLogView;

	// properties
	NSString* serverStatusField;
	NSString* backupStatusField;	
	NSImage* stateImage;
	NSImage* backupStateImage;
	BOOL isStartButtonEnabled;
	BOOL isStopButtonEnabled;		
	BOOL isServerRestarting;
	
	// other
	NSTimer* timer;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTextView* ibLogView;

// properties
@property (retain) NSTimer* timer;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;
@property (assign) BOOL isServerRestarting;
@property (assign) NSString* serverStatusField;
@property (assign) NSString* backupStatusField;
@property (assign) NSImage* stateImage;
@property (assign) NSImage* backupStateImage;
@property (assign) BOOL isStartButtonEnabled;
@property (assign) BOOL isStopButtonEnabled;

// IB Actions
-(IBAction)doServerStart:(id)sender;
-(IBAction)doServerStop:(id)sender;
-(IBAction)doServerBackup:(id)sender;

// methods
-(void)addLogMessage:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold;

@end
