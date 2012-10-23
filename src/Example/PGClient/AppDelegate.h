
#import <Cocoa/Cocoa.h>
#import "PGLoginController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (retain) PGLoginController* loginController;

-(IBAction)doLogin:(id)sender;

@end
