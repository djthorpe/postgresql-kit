
#import "HostAccessViewController.h"

@implementation HostAccessViewController

-(NSString* )nibName {
	return @"HostAccessView";
}

-(NSString* )identifier {
	return @"hostaccess";
}

-(void)loadView {
	[super loadView];
	NSLog(@"view size = %@",NSStringFromSize([self frameSize]));
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}

@end
