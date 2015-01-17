
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface ConnectionsViewController : ViewController <NSTableViewDataSource> {
	IBOutlet NSTableView* _tableView;
}

@property PGResult* connections;
@property NSTimer* timer;

@end
