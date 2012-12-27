
#import "ViewController.h"

@implementation ViewController

@dynamic tag;

-(void)loadView {
	[super loadView];
	[self setFrameSize:[[self view] frame].size];
}

// called just before view is selected, return NO to
// not select the view
-(BOOL)willSelectView:(id)sender {
	return YES;
}

// called just before view is selected, return NO to
// not unselect the view
-(BOOL)willUnselectView:(id)sender {
	return YES;
}

-(NSInteger)tag {
	return -1;
}

@end
