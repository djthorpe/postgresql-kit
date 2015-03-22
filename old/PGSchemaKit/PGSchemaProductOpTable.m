
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

#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

@implementation PGSchemaProductOpTable

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	if(isDryrun) {
		// TODO: check to make sure table is not created
	} else {
		NSString* statement = [PGSchemaManager sqlWithFormat:@"PGSchemaProductOpTableCreate" attributes:[self attributes] error:error];
		if(statement==nil) {
			return NO;
		}
		NSLog(@"TODO: Create %@",statement);
	}
	return YES;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Update %@",self);
	return NO;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Drop %@",self);
	return NO;
}

@end
