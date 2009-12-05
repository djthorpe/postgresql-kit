
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    // IBOutlets
	NSWindow* window;
	NSTextView* ibLogView;

	// button enabled states
	BOOL isStartButtonEnabled;
	BOOL isStopButtonEnabled;	
	
	// status values
	NSString* serverStatusField;
	NSString* backupStatusField;	
	
	// other
	NSTimer* timer;
}

@property (assign) IBOutlet NSWindow* window;
@property (retain) IBOutlet NSTextView* ibLogView;
@property (retain) NSTimer* timer;
@property (retain) NSString* serverStatusField;
@property (retain) NSString* backupStatusField;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;
@property (assign) BOOL isStartButtonEnabled;
@property (assign) BOOL isStopButtonEnabled;

-(IBAction)doServerStart:(id)sender;
-(IBAction)doServerStop:(id)sender;
-(IBAction)doServerBackup:(id)sender;
-(IBAction)doServerAccess:(id)sender;	

@end
