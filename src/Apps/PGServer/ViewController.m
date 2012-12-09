
#import "ViewController.h"

@implementation ViewController

-(void)loadView {
	[super loadView];
	[self setFrameSize:[[self view] frame].size];
}

// called just before view is selected, return NO to
// not select the view
-(BOOL)willSelectView:(id)sender {
	return YES;
}

@end
