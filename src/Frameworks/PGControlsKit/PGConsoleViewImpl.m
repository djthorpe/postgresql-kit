
#import "PGControlsKit.h"
#import "PGControlsKit+Private.h"

@implementation PGConsoleViewImpl

-(void)keyDown:(NSEvent* )theEvent {
	PGConsoleView* delegate = (PGConsoleView* )[self delegate];
	NSParameterAssert([delegate isKindOfClass:[PGConsoleView class]]);
	if([delegate editable] && [delegate respondsToSelector:@selector(keyDown:)]) {
		[delegate keyDown:theEvent];
	} else {
		[super keyDown:theEvent];		
	}
}

@end
