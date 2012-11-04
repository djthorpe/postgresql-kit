
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import "AppDelegate.h"

@interface ConfigurationPrefs : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet AppDelegate* appController;
@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTableView* ibTableView;
@property (readonly) PGServerPreferences* configuration;
@property (assign) NSString* ibComment;

-(IBAction)ibToolbarConfigurationSheetOpen:(id)sender;

@end
