
#import <Cocoa/Cocoa.h>

@interface HostAccessArrayController : NSArrayController <NSTableViewDataSource> {
	NSTableView* ibTableView;
}

@property (assign) IBOutlet NSTableView* ibTableView;

@end
