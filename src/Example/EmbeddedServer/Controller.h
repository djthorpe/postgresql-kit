
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "Bindings.h"

@interface Controller : NSObject {
	FLXPostgresServer* server;
	FLXPostgresConnection* client;

	// IBOutlet
	IBOutlet Bindings* bindings;
}

@property (retain) FLXPostgresServer* server;
@property (retain) FLXPostgresConnection* client;
@property (retain) Bindings* bindings;

// actions
-(IBAction)doStartServer:(id)sender;
-(IBAction)doStopServer:(id)sender;
-(IBAction)doBackupServer:(id)sender;
-(IBAction)doExecuteCommand:(id)sender;
-(IBAction)doSelectDatabase:(id)sender;
-(IBAction)doEndSelectDatabase:(id)sender;
-(IBAction)doClearOutput:(id)sender;
-(IBAction)doAccessEdit:(id)sender;
-(IBAction)doEndAccessEdit:(id)sender;

@end
