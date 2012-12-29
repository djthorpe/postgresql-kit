
#import "UsersRolesViewController.h"
#import "AppDelegate.h"

@implementation UsersRolesViewController

-(NSString* )nibName {
	return @"UsersRolesView";
}

-(NSString* )identifier {
	return @"users";
}


-(NSInteger)tag {
	return 4;
}

-(void)loadView {
	[super loadView];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitView delegate methods

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [_resizeView convertRect:[_resizeView bounds] toView:splitView];
}

@end
