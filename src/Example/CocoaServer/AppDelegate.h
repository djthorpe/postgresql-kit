
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* window;
	NSString* textField;
	NSString* serverStatusField;
	NSString* backupStatusField;
	NSMutableString* textLog;
}

@property (assign) IBOutlet NSWindow* window;
@property (retain) NSString* textField;
@property (retain) NSMutableString* textLog;
@property (readonly) FLXPostgresServer* server;
@property (readonly) NSString* dataPath;
@property (retain) NSTimer* timer;
@property (retain) NSString* serverStatusField;
@property (retain) NSString* backupStatusField;

-(IBAction)doServerStart:(id)sender;
-(IBAction)doServerStop:(id)sender;
-(IBAction)doServerBackup:(id)sender;
-(IBAction)doServerAccess:(id)sender;	

@end
