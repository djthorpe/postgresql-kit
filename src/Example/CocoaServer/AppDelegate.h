
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    // IBOutlets
	NSWindow* window;
	NSTextView* ibLogView;
	NSWindow* ibPreferencesWindow;

	// button enabled states
	BOOL isStartButtonEnabled;
	BOOL isStopButtonEnabled;	
	
	// status values
	NSString* serverStatusField;
	NSString* backupStatusField;	
	NSUInteger port;
	BOOL isDefaultPort;	
	BOOL isAllowRemoteConnections;
	
	// other
	NSTimer* timer;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSWindow* ibPreferencesWindow;
@property (assign) IBOutlet NSTextView* ibLogView;

// properties
@property (retain) NSTimer* timer;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;

// bindings
@property (retain) NSString* serverStatusField;
@property (retain) NSString* backupStatusField;
@property (assign) BOOL isStartButtonEnabled;
@property (assign) BOOL isStopButtonEnabled;
@property (assign) NSUInteger port;
@property (assign) BOOL isAllowRemoteConnections;
@property (assign) BOOL isDefaultPort;


// IB Actions
-(IBAction)doServerStart:(id)sender;
-(IBAction)doServerStop:(id)sender;
-(IBAction)doServerBackup:(id)sender;
-(IBAction)doServerAccess:(id)sender;	
-(IBAction)doPreferences:(id)sender;
-(IBAction)doPreferencesButton:(id)sender;

@end
