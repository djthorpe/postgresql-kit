
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
#import "PGSourceViewConnection.h"

@implementation PGSourceViewConnection

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize iconStatus;
@dynamic URL;

-(void)setURL:(NSURL* )url {
	[_dictionary setObject:[url absoluteString] forKey:@"URL"];
}

-(NSURL* )URL {
	return [NSURL URLWithString:[[self dictionary] objectForKey:@"URL"]];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSImage* )imageForStatus:(PGSourceViewConnectionIcon)status {
	NSBundle* thisBundle = [NSBundle bundleForClass:[self class]];
	NSParameterAssert(thisBundle);
	switch(status) {
	case PGSourceViewConnectionIconConnecting:
		return [thisBundle imageForResource:@"traffic-orange"];
	case PGSourceViewConnectionIconConnected:
		return [thisBundle imageForResource:@"traffic-green"];
	case PGSourceViewConnectionIconRejected:
		return [thisBundle imageForResource:@"traffic-red"];
	default:
		return [thisBundle imageForResource:@"traffic-grey"];
	}
}

////////////////////////////////////////////////////////////////////////////////
// overrides

-(BOOL)isGroupItem {
	return NO;
}

-(BOOL)isSelectable {
	return YES;
}

-(BOOL)isNameEditable {
	return YES;
}

-(BOOL)isDraggable {
	return YES;
}

-(BOOL)isDeletable {
	return YES;
}

-(NSTableCellView* )cellViewForOutlineView:(NSOutlineView* )outlineView tableColumn:(NSTableColumn* )tableColumn owner:(id)owner tag:(NSInteger)tag {
	NSTableCellView* cellView = [super cellViewForOutlineView:outlineView tableColumn:tableColumn owner:owner tag:tag];
	NSParameterAssert(cellView);
	
	NSImage* trafficIcon = [self imageForStatus:[self iconStatus]];
	[[cellView imageView] setImage:trafficIcon];

	return cellView;
}

-(void)writeToPasteboard:(NSPasteboard* )pboard {
	NSParameterAssert(pboard);
	[pboard addTypes:@[ NSURLPboardType ] owner:nil];
	[[self URL] writeToPasteboard:pboard];
}

@end
