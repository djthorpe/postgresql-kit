
#import <Cocoa/Cocoa.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "FLXPostgresConnectWindowController.h"

@interface Controller : NSObject {
	FLXPostgresConnection* client;
	FLXPostgresConnectWindowController* connectPanel;

	// IBOutlets
	IBOutlet NSWindow* ibMainWindow;
}

@property (retain) FLXPostgresConnectWindowController* connectPanel;
@property (retain) FLXPostgresConnection* client;

@end
