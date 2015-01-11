
#import "Application.h"

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@end

@implementation Application

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [Connection new];
		_splitView = [PGSplitViewController new];
	}
	NSParameterAssert(_connection && _splitView);
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize splitView = _splitView;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)addSplitView {
	NSView* contentView = [[self window] contentView];

	// add splitview to the content view
	NSView* splitView = [[self splitView] view];
	[contentView addSubview:splitView];
	[splitView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary *views = NSDictionaryOfVariableBindings(splitView);
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[splitView]|" options:0 metrics:nil views:views]];
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[splitView]|" options:0 metrics:nil views:views]];
}

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// add PGSplitView to the content view
	[self addSplitView];
	
	// connect to remote server
	[[self connection] loginWithWindow:[self window]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote server
	[[self connection] disconnect];
}

@end
