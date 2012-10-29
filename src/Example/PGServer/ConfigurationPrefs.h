
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import "AppDelegate.h"

@interface ConfigurationPrefs : NSObject

@property (assign) IBOutlet AppDelegate* appController;
@property (assign) IBOutlet NSWindow* ibWindow;
@property (readonly) PGServerPreferences* configuration;

-(IBAction)ibToolbarConfigurationSheetOpen:(id)sender;

@end
