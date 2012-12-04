
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "AppDelegate.h"

@interface ConnectionPreferences : NSObject {
    // IBOutlets
	NSWindow* ibMainWindow;
	NSWindow* ibConnectionWindow;	
	// properties
	AppDelegate* ibAppDelegate;
	NSUInteger port;
	BOOL isCustomPort;	
	NSInteger selectedPortOption;
	BOOL isAllowRemoteConnections;	
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibMainWindow;
@property (assign) IBOutlet NSWindow* ibConnectionWindow;
@property (assign) IBOutlet AppDelegate* ibAppDelegate;

// properties
@property (readonly) FLXPostgresServer* server;
@property (assign) NSUInteger port;
@property (assign) BOOL isAllowRemoteConnections;
@property (assign) BOOL isCustomPort;
@property (assign) NSInteger selectedPortOption;

// IBActions
-(IBAction)doConnectionPreferences:(id)sender;
-(IBAction)doButton:(id)sender;
-(IBAction)doPortRadioButton:(id)sender;

@end
