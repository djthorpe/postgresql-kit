
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface ConnectionViewController : ViewController

@property (assign) BOOL isRemoteConnection;
@property (assign) NSUInteger port;
@property (assign) BOOL isDefaultPort;

-(IBAction)ibUseDefaultPort:(id)sender;

@end
