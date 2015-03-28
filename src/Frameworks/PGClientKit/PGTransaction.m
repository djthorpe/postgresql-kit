
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

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

@implementation PGTransaction

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if (self) {
        _queries = [NSMutableArray new];
		NSParameterAssert(_queries);
		_transactional = YES;
    }
    return self;
}

+(instancetype)transactionWithQuery:(PGQuery* )query {
	NSParameterAssert(query);
	PGTransaction* transaction = [PGTransaction new];
	NSParameterAssert(transaction);
	[transaction add:query];
	return transaction;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic count;
@synthesize transactional = _transactional;

-(NSUInteger)count {
	return [_queries count];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(NSString* )quoteBeginTransactionForConnection:(PGConnection* )connection {
	NSParameterAssert(connection);
	if([self transactional]) {
		return @"BEGIN TRANSACTION";
	} else {
		return nil;
	}
}

-(NSString* )quoteCommitTransactionForConnection:(PGConnection* )connection {
	NSParameterAssert(connection);
	if([self transactional]) {
		return @"COMMIT TRANSACTION";
	} else {
		return nil;
	}
}


-(NSString* )quoteRollbackTransactionForConnection:(PGConnection* )connection {
	NSParameterAssert(connection);
	if([self transactional]) {
		return @"ROLLBACK TRANSACTION";
	} else {
		return nil;
	}
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(void)add:(PGQuery* )query {
	NSParameterAssert(query);
	[_queries addObject:query];
}

-(PGQuery* )queryAtIndex:(NSUInteger)index {
	NSParameterAssert(index < [_queries count]);
	return [_queries objectAtIndex:index];
}

@end
