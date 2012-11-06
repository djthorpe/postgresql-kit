
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface ConfigurationPrefs : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property id delegate;
@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTableView* ibTableView;
@property (readonly) PGServerPreferences* configuration;
@property (assign) NSString* ibComment;

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender;

@end
