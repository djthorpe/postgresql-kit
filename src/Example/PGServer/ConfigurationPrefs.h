
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface ConfigurationPrefs : NSObject

@property (assign) IBOutlet AppDelegate* appController;
@property (assign) IBOutlet NSWindow* ibWindow;

-(IBAction)ibToolbarConfigurationSheetOpen:(id)sender;

@end
