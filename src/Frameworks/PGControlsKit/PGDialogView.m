
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

@implementation PGDialogView

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructors
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if (self) {
        _parameters = [NSMutableDictionary new];
		NSParameterAssert(_parameters);
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize view;
@synthesize delegate;
@synthesize parameters = _parameters;
@dynamic bindings;

-(NSArray* )bindings {
	// subclass this method
	return @[ ];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////


-(void)_registerKeyValueObserver {
	NSArray* bindings = [self bindings];
	NSParameterAssert(bindings);
	for(NSString* binding in bindings) {
		NSString* keyPath = [NSString stringWithFormat:@"parameters.%@",binding];
		[super addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterKeyValueObserver {
	NSArray* bindings = [self bindings];
	NSParameterAssert(bindings);
	for(NSString* binding in bindings) {
		NSString* keyPath = [NSString stringWithFormat:@"parameters.%@",binding];
		[super removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	NSLog(@"value changed = %@",keyPath);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(void)setViewParameters:(NSDictionary* )parameters {
	NSParameterAssert(parameters);
	[_parameters removeAllObjects];
	[_parameters setValuesForKeysWithDictionary:parameters];
	[self _registerKeyValueObserver];
}

-(void)viewDidEnd {
	[self _deregisterKeyValueObserver];
}

@end
