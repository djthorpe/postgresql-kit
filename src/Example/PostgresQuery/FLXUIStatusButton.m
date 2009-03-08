
#import "FLXUIStatusButton.h"

@interface FLXUIStatusButton (Private) 
-(CGFloat)padding;
-(void)setPadding:(CGFloat)thePadding;
-(NSImage* )triangleImage;
-(NSPopUpButtonCell* )popupButton;
-(void)setPopupButton:(NSPopUpButtonCell* )theButton;
@end

@implementation FLXUIStatusButton

- (id)initWithFrame:(NSRect)frameRect {  
	self = [super initWithFrame:frameRect];
	if(self) {
		m_theImage = [[NSImage imageNamed:@"NSActionTemplate"] copy];
		m_theTriangleImage = [[NSImage imageNamed:@"FLXUIStatusBarTriangle"] copy];
		m_theGradientImage = [[NSImage imageNamed:@"FLXUIStatusBarGradient"] copy];
		m_thePopUpButton = nil;
		m_thePadding = 4.0;
	}
	return self;
}

-(void)finalize {
	if(m_thePopUpButton) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidEndTrackingNotification object:nil];
	}
	[super finalize];
}

-(void)dealloc {
	[self finalize];
	[m_thePopUpButton release];
	[m_theImage release];
	[m_theTriangleImage release];
	[m_theGradientImage release];
	[super dealloc];
}

-(void)awakeFromNib {
	
	// set button properties
	[super setImage:m_theImage];
	[super setImagePosition:NSImageOnly];
	[super setButtonType:NSMomentaryPushInButton];
	[super setBordered:NO];
	
	// flip gradient for background
	[m_theGradientImage setFlipped:YES];
	
	// install menu
	if([self menu]) {
		[self setPopupButton:[[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:YES] autorelease]];
		[[self triangleImage] setFlipped:YES];
		[[self popupButton] setMenu:[self menu]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuClosed:) name:NSMenuDidEndTrackingNotification object:nil];
	}
	
}

-(CGFloat)padding {
	return m_thePadding;
}

-(void)setPadding:(CGFloat)thePadding {
	NSParameterAssert(thePadding >= 0.0);
	m_thePadding = thePadding;
	[self sizeToFit];
}

-(NSImage* )triangleImage {
	return m_theTriangleImage;
}

-(NSPopUpButtonCell* )popupButton {
	return m_thePopUpButton;
}

-(void)setPopupButton:(NSPopUpButtonCell* )theButton {
	[theButton retain];
	[m_thePopUpButton release];
	m_thePopUpButton = theButton;
}

-(void)sizeToFit {
	NSRect theFrame = [self frame];
	theFrame.size.width = ([self padding] * 2.0) + [[self image] size].width + [[self triangleImage] size].width;
	[self setFrame:theFrame];
	[super setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)aRect {
	// determine opacity based on whether enabled or not
	CGFloat theFraction = [self isEnabled] ? 1.0 : 0.0;
	
	// draw the background
	NSRect theGradientRect = NSMakeRect(0, 0, [m_theGradientImage size].width, [m_theGradientImage size].height);
	// Draw the background, tiling a 1px-wide image horizontally	
	[m_theGradientImage drawInRect:[self bounds] fromRect:theGradientRect operation:NSCompositeCopy fraction:1.0];
	
	
	// draw the gear
	NSRect theSourceImageRect = NSMakeRect(0,0,[[self image] size].width,[[self image] size].height);
	NSRect theDestinationImageRect = NSMakeRect([self padding],([self bounds].size.height - [[self image] size].height + [self padding]) / 2.0,[[self image] size].width - [self padding],[[self image] size].height  - [self padding]);
	[[self image] drawInRect:theDestinationImageRect fromRect:theSourceImageRect operation:NSCompositeSourceOver fraction:theFraction];    
	// draw the triangle
	if([self triangleImage]) {
		NSRect theSourceImageRect = NSMakeRect(0,0,[[self triangleImage] size].width,[[self triangleImage] size].height);
		NSRect theDestinationImageRect = NSMakeRect(([self padding] + [[self image] size].width),(([self bounds].size.height - [[self triangleImage] size].height) / 2.0),[[self triangleImage] size].width,[[self triangleImage] size].height);
		[[self triangleImage] drawInRect:theDestinationImageRect fromRect:theSourceImageRect operation:NSCompositeSourceOver fraction:theFraction];        
	}
	
	// if button is pressed, draw black background
	if([self state] != NSOffState) {
		[[NSColor grayColor] set];
		NSRectFillUsingOperation([self bounds],NSCompositePlusDarker);
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	if(m_thePopUpButton && [self isEnabled]) {
		[self setState:NSOnState];
		[m_thePopUpButton performClickWithFrame:[self bounds] inView:self];
	}
}

-(void)menuClosed:(NSNotification *)note {
	[self setState:NSOffState];
}

@end
