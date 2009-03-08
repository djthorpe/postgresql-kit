
#import "ServerController.h"

@implementation ServerController

///////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		m_isReady = NO;
	}
	return self;
}

-(void)dealloc {
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
// properties

-(FLXServer* )server {
	return [FLXServer sharedServer];
}

-(BOOL)isStarted {
	return [[self server] isRunning];
}

-(BOOL)isReady {
	return m_isReady;
}

///////////////////////////////////////////////////////////////////////////////
// outlets

-(NSWindow* )startupSheet {
	return m_theStartupSheet;
}

-(NSProgressIndicator* )startupProgressIndicator {
	return m_theProgressIndicator;
}

-(NSTextView* )startupTextView {
	return m_theTextView;
}

-(NSTextField* )startupTextField {
	return m_theTextField;
}

///////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_dataPath {
	NSArray* theIdent = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	NSParameterAssert([theIdent count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:[theIdent objectAtIndex:([theIdent count]-1)]];
}

-(void)_startServer {
	// start the server
	
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self _dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self _dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    	
}

-(void)_stopServer {
	[[self server] stop];
}

-(void)_startupTextViewScrollToBottom {
	NSClipView* theClipView = (NSClipView* )[[self startupTextView] superview];
	NSRect docRect = [[self startupTextView] frame];
	NSRect clipRect = [theClipView bounds];
	float theVerticalPoint = docRect.size.height - clipRect.size.height + 30.0f;
	if(theVerticalPoint > 30.0f) {
		[theClipView scrollToPoint:NSMakePoint(0,theVerticalPoint)];
	}
}

///////////////////////////////////////////////////////////////////////////////
// public methods

-(void)startServerWithWindow:(NSWindow* )theWindow {	
	// setup the sheet, switch on busy indicator
	[[self startupTextField] setStringValue:@"Starting"];
	[[self startupProgressIndicator] startAnimation:self];
	// display the sheet
	[NSApp beginSheet:[self startupSheet] modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(didEndStartupSheet:returnCode:contextInfo:) contextInfo:nil];
	// start the server
	[self _startServer];
}

-(void)stopServerWithWindow:(NSWindow* )theWindow {
	// setup the sheet, switch on busy indicator
	[[self startupTextField] setStringValue:@"Stopping"];
	[[self startupProgressIndicator] startAnimation:self];
	// display the sheet
	[NSApp beginSheet:[self startupSheet] modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(didEndStartupSheet:returnCode:contextInfo:) contextInfo:nil];
	// stop the server
	[self _stopServer];	
}

///////////////////////////////////////////////////////////////////////////////
// awake from nib

-(void)awakeFromNib {
	// set up server parameters
	[[self server] setDelegate:self];
	[[self server] setPort:9001];
	
	// set delegate
	[[self server] setDelegate:self];
}

///////////////////////////////////////////////////////////////////////////////
// startup sheet was ended

-(void)didEndStartupSheet:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	// stop progress indicator
	[[self startupProgressIndicator] stopAnimation:self];	
}

////////////////////////////////////////////////////////////////////////////////
// FLXServer delegate messages

-(void)serverMessage:(NSString* )theMessage {
	NSMutableAttributedString* theLog = [[self startupTextView] textStorage];
	NSAttributedString* theLine = [[NSAttributedString alloc] initWithString:theMessage];
	NSAttributedString* theNewline = [[NSAttributedString alloc] initWithString:@"\n"];
	[theLog appendAttributedString:theLine];
	[theLog appendAttributedString:theNewline];
	[theLine release];
	[theNewline release];
	[self _startupTextViewScrollToBottom];
}

-(void)serverStateDidChange:(NSString* )theMessage {
	// set the text value
	[[self startupTextField] setStringValue:theMessage];  

	// append message
	[self serverMessage:theMessage];

	// check for server started
	if([[FLXServer sharedServer] state]==FLXServerStateStarted) {
		// remove the sheet
		[NSApp endSheet:[self startupSheet]];
		// set ready condition
		m_isReady = YES;
	}
}

@end

