
#import "LogViewController.h"
#import "AppDelegate.h"

@implementation LogViewController

-(NSString* )nibName {
	return @"LogView";
}

-(NSString* )identifier {
	return @"log";
}

-(NSInteger)tag {
	return 0;
}

-(void)loadView {
	[super loadView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:PGServerMessageNotificationFatal object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:PGServerMessageNotificationError object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:PGServerMessageNotificationWarning object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:PGServerMessageNotificationInfo object:nil];
}

-(void)addLogMessage:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold {
	NSMutableAttributedString* theLog = [_textView textStorage];
	NSUInteger theStartPoint = [theLog length];
	NSFont* theFont = [NSFont userFixedPitchFontOfSize:9.0];
	NSDictionary* theAttributes = nil;
	if(theColor) {
		theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theColor,NSForegroundColorAttributeName,nil];
	}
	NSMutableAttributedString* theLine = nil;
	if(theStartPoint) {
		theLine = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",theString] attributes:theAttributes];
	} else {
		theLine = [[NSMutableAttributedString alloc] initWithString:theString attributes:theAttributes];
	}
	[theLine addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,nil] range:NSMakeRange(0,[theLine length])];
	if(isBold) {
		[theLine applyFontTraits:NSBoldFontMask range:NSMakeRange(0,[theLine length])];
	} else {
		[theLine applyFontTraits:NSUnboldFontMask range:NSMakeRange(0,[theLine length])];
	}
	[theLog appendAttributedString:theLine];
	[_textView scrollRangeToVisible:NSMakeRange(theStartPoint,[theLog length])];
}

-(void)log:(NSNotification* )notification {
	NSString* message = (NSString* )[notification object];
	NSParameterAssert(message && [message isKindOfClass:[NSString class]]);
	if([[notification name] isEqualToString:PGServerMessageNotificationFatal]) {
		[self addLogMessage:message color:[NSColor redColor] bold:YES];
	} else if([[notification name] isEqualToString:PGServerMessageNotificationError]) {
		[self addLogMessage:message color:[NSColor redColor] bold:NO];
	} else if([[notification name] isEqualToString:PGServerMessageNotificationWarning]) {
		[self addLogMessage:message color:[NSColor redColor] bold:NO];
	} else {
		[self addLogMessage:message color:[NSColor whiteColor] bold:NO];
	}
}

-(IBAction)doClearLog:(id)sender {
	NSMutableAttributedString* theLog = [_textView textStorage];
	[theLog deleteCharactersInRange:NSMakeRange(0,[theLog length])];
}


@end
