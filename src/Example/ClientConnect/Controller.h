
#import <Cocoa/Cocoa.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "FLXPostgresConnectWindowController.h"

@interface Controller : NSObject {
	FLXPostgresConnectWindowController* connectPanel;

	// IBOutlets
	IBOutlet NSWindow* ibMainWindow;
}

@property (retain) FLXPostgresConnectWindowController* connectPanel;

@end
