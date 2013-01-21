
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface DatabaseViewController : ViewController <NSTableViewDataSource, NSSplitViewDelegate, NSTableViewDelegate> {
	IBOutlet NSWindow* _createDatabaseSheet;
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
	IBOutlet NSTableView* _tableView;
}

@property PGResult* result;

// IBActions
-(IBAction)ibCreateDatabase:(id)sender;
-(IBAction)ibDropDatabase:(id)sender;
-(IBAction)ibBackupDatabase:(id)sender;

@end
