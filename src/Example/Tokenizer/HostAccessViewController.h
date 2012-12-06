
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface HostAccessViewController : ViewController <NSSplitViewDelegate> {
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
}

@end
