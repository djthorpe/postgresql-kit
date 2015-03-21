
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
#import <PGControlsKit/PGControlsKit+Private.h>

@implementation PGDialogFileConnectionView


////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

-(NSString* )windowTitle {
	return @"Create File Socket Connection";
}

-(NSString* )windowDescription {
	return @"Enter the details for the connection to the local PostgreSQL database";
}


-(NSURL* )url {
	NSMutableDictionary* url = [NSMutableDictionary dictionaryWithDictionary:[self parameters]];

	// remove parameters which aren't part of the URL
	[url removeObjectForKey:@"comment"];
	[url removeObjectForKey:@"is_require_ssl"];
	[url removeObjectForKey:@"is_default_port"];
	
	// if missing user, host or dbname, return nil
	if([self user]==nil) {
		return nil;
	}
	if([self dbname]==nil) {
		return nil;
	}
	if([self host]==nil) {
		return nil;
	}
	return [NSURL URLWithPostgresqlParams:url];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark IBActions
////////////////////////////////////////////////////////////////////////////////

-(IBAction)pathControlDoubleClick:(NSPathControl* )sender {
	NSWindow* window = [sender window];
	NSParameterAssert(window);

	// determine URL
	NSURL* url = [NSURL fileURLWithPath:[self host]];
	if([sender clickedPathComponentCell]) {
		url = [[sender clickedPathComponentCell] URL];
	}
	
	// Create file chooser
	NSOpenPanel* panel = [NSOpenPanel new];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setDirectoryURL:url];

	// Perform sheet
	[panel beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnValue) {
		if(returnValue==NSModalResponseOK) {
			NSString* thePath = [[panel URL] path];
			[[self parameters] setObject:thePath forKey:@"host"];
		}
	}];
}

@end
