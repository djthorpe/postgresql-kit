
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>
#import "ControllerDelegate.h"

@interface ConfigurationPrefs : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property id<ControllerDelegate> delegate;
@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTableView* ibTableView;
@property (assign) NSString* ibComment;

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender;

@end
