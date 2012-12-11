
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface DatabaseViewController : ViewController <NSTableViewDataSource, NSSplitViewDelegate, NSTableViewDelegate> {
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
	IBOutlet NSTableView* _tableView;
}

@property PGResult* result;

@end
