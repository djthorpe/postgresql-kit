//
//  Bindings.m
//  postgresql
//
//  Created by David Thorpe on 08/03/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Bindings.h"

@implementation Bindings
@synthesize databases;

-(NSWindow* )mainWindow {
	return ibMainWindow;
}

-(NSWindow* )selectWindow {
	return ibSelectWindow;
}

-(NSMutableAttributedString* )outputString {
	return [ibOutput textStorage];
}

-(void)clearOutput {
	[[self outputString] deleteCharactersInRange:NSMakeRange(0,[[self outputString] length])];	
}

-(void)appendOutputString:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold {
	NSUInteger theStartPoint = [[self outputString] length];
	NSFont* theFont = [NSFont userFixedPitchFontOfSize:11.0];
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
	[[self outputString] appendAttributedString:theLine];
	[theLine release];	
	[ibOutput scrollRangeToVisible:NSMakeRange(theStartPoint,[theString length])];	
}

-(void)setInputEnabled:(BOOL)isEnabled {
	[ibInput setEnabled:isEnabled];
	if(isEnabled) {
		[ibInput setBackgroundColor:[NSColor whiteColor]];
		[ibMainWindow makeFirstResponder:ibInput];
	} else {
		[ibInput setBackgroundColor:[NSColor grayColor]];		
	}
}

-(NSString* )inputString {
	return [[ibInput stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(void)setInputString:(NSString* )theString {
	[ibInput setStringValue:theString];
}


@end
