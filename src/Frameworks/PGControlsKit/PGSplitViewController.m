
#import "PGSplitViewController.h"

@interface PGSplitViewController ()

@end

@implementation PGSplitViewController

-(id)init {
    NSString* nibName = @"PGSplitView";
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];;
    return [super initWithNibName:nibName bundle:bundle];
}

-(void)loadView {
	[super loadView];
	// set delegate
	[(NSSplitView* )[self view] setDelegate:self];
}

////////////////////////////////////////////////////////////////////////////////
// NSSplitViewDelegate

-(NSRect)splitView:(NSSplitView* )splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	NSParameterAssert([self ibGrabberView]);
	return [[self ibGrabberView] convertRect:[[self ibGrabberView] bounds] toView:splitView];
}

-(CGFloat)splitView:(NSSplitView* )splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
	// constrain view to width of grabber view
	NSParameterAssert([self ibGrabberView]);
	CGFloat grabberWidth = [[self ibGrabberView] bounds].size.width;
	if(proposedPosition < grabberWidth) {
		proposedPosition = grabberWidth;
	}
	return proposedPosition;
}



@end
