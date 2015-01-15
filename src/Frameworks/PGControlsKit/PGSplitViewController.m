
#import <PGControlsKit/PGControlsKit.h>

@interface PGSplitViewController ()

@property (assign) IBOutlet NSView* ibGrabberView;
@property (weak) IBOutlet NSView* ibLeftView;
@property (weak) IBOutlet NSView* ibRightView;

@end

@implementation PGSplitViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

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
// private methods

-(BOOL)setView:(NSView* )subView parentView:(NSView* )parentView {
	NSParameterAssert(subView && parentView);

	// add splitview to the content view
	[parentView addSubview:subView];
	[subView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary* views = NSDictionaryOfVariableBindings(subView);
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:nil views:views]];
	[parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:nil views:views]];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)setLeftView:(id)viewOrController {
	NSParameterAssert([viewOrController isKindOfClass:[NSView class]] || [viewOrController isKindOfClass:[NSViewController class]]);
	if([viewOrController isKindOfClass:[NSViewController class]]) {
		return [self setView:[viewOrController view] parentView:[self ibLeftView]];
	} else if([viewOrController isKindOfClass:[NSView class]]) {
		return [self setView:viewOrController parentView:[self ibLeftView]];
	} else {
		return NO;
	}
}

-(BOOL)setRightView:(id)viewOrController {
	NSParameterAssert([viewOrController isKindOfClass:[NSView class]] || [viewOrController isKindOfClass:[NSViewController class]]);
	if([viewOrController isKindOfClass:[NSViewController class]]) {
		return [self setView:[viewOrController view] parentView:[self ibRightView]];
	} else if([viewOrController isKindOfClass:[NSView class]]) {
		return [self setView:viewOrController parentView:[self ibRightView]];
	} else {
		return NO;
	}
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
