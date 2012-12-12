
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import <PGClientKit/PGClientKit.h>
#import "ViewController.h"

extern NSString* PGServerMessageNotificationError;
extern NSString* PGServerMessageNotificationWarning;
extern NSString* PGServerMessageNotificationFatal;
extern NSString* PGServerMessageNotificationInfo;

@interface AppDelegate : NSObject <ViewControllerDelegate,PGServerDelegate,NSApplicationDelegate> {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSWindow* _closeConfirmSheet;
	IBOutlet NSTabView* _tabView;
	NSMutableDictionary* _views;
	PGConnection* _connection;
	PGServer* _server;
}

// properties
@property (readonly) PGServer* server;
@property (readonly) PGConnection* connection;
@property (retain) NSString* uptimeString;
@property (retain) NSString* statusString;
@property (retain) NSString* versionString;
@property (retain) NSString* buttonText;
@property (assign) BOOL buttonEnabled;
@property (assign) BOOL serverRunning;
@property (assign) BOOL serverStopped;
@property (assign) BOOL clientConnected;
@property (retain) NSImage* buttonImage;
@property (assign) BOOL terminateRequested;

// toolbar item
-(IBAction)ibToolbarItemClicked:(id)sender;

@end
