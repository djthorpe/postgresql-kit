
#import <Cocoa/Cocoa.h>
#import "ConnectionPrefs.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTextView* ibLogTextView;
@property (assign) IBOutlet ConnectionPrefs* ibConnectionPrefs;

@property BOOL ibStartButtonEnabled;
@property BOOL ibStopButtonEnabled;
@property BOOL ibBackupButtonEnabled;
@property NSImage* ibServerStatusIcon;
@property NSString* ibServerVersion;

-(void)stopServer;
-(void)restartServer;

@end

