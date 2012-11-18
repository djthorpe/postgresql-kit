
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import <PGClientKit/PGClientKit.h>

#import "ConnectionPrefs.h"
#import "ConfigurationPrefs.h"
#import "ControllerDelegate.h"

@interface Controller : NSObject <NSApplicationDelegate,ControllerDelegate,PGServerDelegate> {
	PGConnection* _connection;
	PGServer* _server;
}

// objects
@property (readonly) PGServer* server;
@property (readonly) PGConnection* connection;

// UI control properties
@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTextView* ibLogTextView;
@property (assign) IBOutlet NSToolbarItem* ibToolbarItemConnection;
@property (assign) IBOutlet NSToolbarItem* ibToolbarItemConfiguration;

// controllers
@property (assign) IBOutlet ConnectionPrefs* ibConnectionPrefs;
@property (assign) IBOutlet ConfigurationPrefs* ibConfigurationPrefs;

// flags
@property BOOL ibStartButtonEnabled;
@property BOOL ibStopButtonEnabled;
@property BOOL ibBackupButtonEnabled;
@property NSImage* ibServerStatusIcon;
@property NSString* ibServerVersion;
@property NSDate* terminateRequested;

// methods
-(void)stopServer;
-(void)restartServer;

@end
