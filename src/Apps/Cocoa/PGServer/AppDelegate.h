
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import <PGClientKit/PGClientKit.h>
#import "AppPreferences.h"
#import "ViewController.h"


extern NSString* PGServerMessageNotificationError;
extern NSString* PGServerMessageNotificationWarning;
extern NSString* PGServerMessageNotificationFatal;
extern NSString* PGServerMessageNotificationInfo;

@interface AppDelegate : NSObject <ViewControllerDelegate,PGServerDelegate,NSApplicationDelegate> {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSWindow* _closeConfirmSheet;
	IBOutlet NSTabView* _tabView;
	IBOutlet AppPreferences* _preferences;
	NSMutableDictionary* _views;
	PGConnection* _connection;
	PGServer* _server;
}

// properties
@property (readonly) PGServer* server;
@property (readonly) PGConnection* connection;
@property (readonly) AppPreferences* preferences;
@property (readonly) NSWindow* mainWindow;
@property (retain) NSString* uptimeString;
@property (retain) NSString* statusString;
@property (retain) NSString* versionString;
@property (assign) NSUInteger numberOfConnections;
@property (retain) NSString* buttonText;
@property (assign) BOOL buttonEnabled;
@property (assign) BOOL serverRunning;
@property (assign) BOOL serverStopped;
@property (assign) BOOL clientConnected;
@property (retain) NSImage* buttonImage;
@property (assign) BOOL terminateRequested;

// toolbar/menu items clicked
-(IBAction)ibToolbarItemClicked:(id)sender;
-(IBAction)ibViewMenuItemClicked:(NSMenuItem* )menuItem;
-(IBAction)ibServerMenuItemClicked:(NSMenuItem* )menuItem;
-(IBAction)ibStatusStringClicked:(id)sender;

@end
