
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGControlsKit/PGControlsKit.h>
#import "PGOutlineView.h"

@interface PGSourceViewController (PGOutlineViewDelegate)
-(NSMenu* )menuForItem:(id)item;
@end

@implementation PGOutlineView

-(BOOL)performKeyEquivalent:(NSEvent* )theEvent {
	NSString* chars = [theEvent charactersIgnoringModifiers];
    if([theEvent type] == NSKeyDown && [chars length] == 1) {
        int val = [chars characterAtIndex:0];
        // check for a delete
        if (val == 127 || val == 63272) {
            if ([[self delegate] respondsToSelector:@selector(doDeleteKeyPressed:)]) {
                [[self delegate] performSelector:@selector(doDeleteKeyPressed:) withObject:self];
                return YES;
            }
        }
    }
    return [super performKeyEquivalent:theEvent];
}

-(NSMenu* )menuForEvent:(NSEvent* )theEvent {
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    id item = [self itemAtRow:[self rowAtPoint:pt]];
	if(item && [[self delegate] isKindOfClass:[PGSourceViewController class]]) {
		return [(PGSourceViewController* )[self delegate] menuForItem:item];
	} else {
		return nil;
	}
}

@end
