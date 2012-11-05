
#import <Cocoa/Cocoa.h>
#import "ConnectionPrefs.h"
#import "ConfigurationPrefs.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTextView* ibLogTextView;
@property (assign) IBOutlet ConnectionPrefs* ibConnectionPrefs;
@property (assign) IBOutlet ConfigurationPrefs* ibConfigurationPrefs;

@property BOOL ibStartButtonEnabled;
@property BOOL ibStopButtonEnabled;
@property BOOL ibBackupButtonEnabled;
@property NSImage* ibServerStatusIcon;
@property NSString* ibServerVersion;

-(void)stopServer;
-(void)restartServer;

@end

@interface NSObject (AppDelegate)
-(void)restartServer;
-(void)reloadServer;
@end

