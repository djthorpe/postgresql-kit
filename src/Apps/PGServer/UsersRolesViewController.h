
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface UsersRolesViewController : ViewController <NSSplitViewDelegate> {
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
	IBOutlet NSTableView* _tableView;
}

@end
