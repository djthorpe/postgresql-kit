
#import "TerminalView.h"

@implementation TerminalView

-(id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setAntiAlias:YES];
		[self setLineHeight:1];
    }
    return self;
}

-(void)drawRect:(NSRect)dirtyRect {
	// Configure graphics
	[[NSGraphicsContext currentContext] setShouldAntialias:[self antiAlias]];
	[[NSGraphicsContext currentContext] setCompositingOperation: NSCompositeCopy];
	
	// Where to start drawing?
	NSInteger lineStart = dirtyRect.origin.y / [self lineHeight];
	NSInteger lineEnd = lineStart + ceil(dirtyRect.size.height / [self lineHeight]);
	if(lineStart < 0) lineStart = 0;
	
	// Draw each line
	for(NSInteger line = lineStart; line < lineEnd; line++) {
		NSRect lineRect = [self visibleRect];
		lineRect.origin.y = line * [self lineHeight];
		lineRect.size.height = [self lineHeight];
		if([self needsToDrawRect:lineRect]) {
			[self _drawLine:line y:(line * [self lineHeight])];
		}
	}
}

@end
