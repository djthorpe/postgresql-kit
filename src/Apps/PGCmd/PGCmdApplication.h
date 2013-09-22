
#import <Cocoa/Cocoa.h>
#import <PGControlsKit/PGControlsKit.h>

@interface PGCmdApplication : NSObject <NSApplicationDelegate, PGConsoleViewDelegate>
@property (assign) IBOutlet NSWindow* window;
@property (retain) PGConsoleView* view;
@end
