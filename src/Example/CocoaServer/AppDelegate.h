
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    // IBOutlets
	NSWindow* window;
	NSTextView* ibLogView;
	NSWindow* ibPreferencesWindow;
	NSWindow* ibHostAccessWindow;

	// properties
	NSString* serverStatusField;
	NSString* backupStatusField;	
	NSImage* stateImage;
	NSImage* backupStateImage;
	BOOL isStartButtonEnabled;
	BOOL isStopButtonEnabled;		
	NSUInteger port;
	BOOL isCustomPort;	
	NSInteger selectedPortOption;
	BOOL isAllowRemoteConnections;
	BOOL isServerRestarting;
	
	// array of host access tuples
	NSMutableArray* hostAccessTuples;
	
	// other
	NSTimer* timer;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSWindow* ibPreferencesWindow;
@property (assign) IBOutlet NSWindow* ibHostAccessWindow;
@property (assign) IBOutlet NSTextView* ibLogView;

// properties
@property (retain) NSTimer* timer;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;
@property (assign) BOOL isServerRestarting;
@property (retain) NSMutableArray* hostAccessTuples;

// bindings
@property (assign) NSString* serverStatusField;
@property (assign) NSString* backupStatusField;
@property (assign) NSImage* stateImage;
@property (assign) NSImage* backupStateImage;
@property (assign) BOOL isStartButtonEnabled;
@property (assign) BOOL isStopButtonEnabled;
@property (assign) NSUInteger port;
@property (assign) BOOL isAllowRemoteConnections;
@property (assign) BOOL isCustomPort;
@property (assign) NSInteger selectedPortOption;

// IB Actions
-(IBAction)doServerStart:(id)sender;
-(IBAction)doServerStop:(id)sender;
-(IBAction)doServerBackup:(id)sender;
-(IBAction)doPreferences:(id)sender;
-(IBAction)doPreferencesButton:(id)sender;
-(IBAction)doPortRadioButton:(id)sender;
-(IBAction)doHostAccess:(id)sender;
-(IBAction)doHostAccessButton:(id)sender;

@end
