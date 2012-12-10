
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface ConfigurationViewController : ViewController <NSTableViewDataSource, NSSplitViewDelegate, NSTableViewDelegate> {
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
	IBOutlet NSTableView* _tableView;
}

@property NSString* ibKeyString;
@property NSString* ibValueString;
@property NSString* ibCommentString;
@property BOOL ibEnabled;

@end
