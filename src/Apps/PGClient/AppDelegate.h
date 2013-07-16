
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, PGLoginDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (retain) PGLoginController* loginController;

-(IBAction)doLogin:(id)sender;

@end
