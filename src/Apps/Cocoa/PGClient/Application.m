
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
		_sourceView = [PGSourceViewController new];
		NSParameterAssert(_connection && _splitView && _sourceView);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;

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
	
	// add left and right views
	[[self splitView] setLeftView:[self sourceView]];
	
	// add headings
	[[self sourceView] addHeadingWithTitle:@"CONNECTIONS"];
	[[self sourceView] addHeadingWithTitle:@"QUERIES"];
}

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// add PGSplitView to the content view
	[self addSplitView];
	
	// connect to remote server
	[[self connection] loginSheetWithWindow:[self window]];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote server
	[[self connection] disconnect];
}

@end
