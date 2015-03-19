
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

NSString* PGDialogKeyPathPrefix = @"parameters";

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
#pragma mark private methods - bindings
////////////////////////////////////////////////////////////////////////////////

-(void)registerBindings {
	NSArray* bindings = [self bindings];
	NSParameterAssert(bindings);
	for(NSString* binding in bindings) {
		NSString* keyPath = [NSString stringWithFormat:@"%@.%@",PGDialogKeyPathPrefix,binding];
		[super addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)deregisterBindings {
	NSArray* bindings = [self bindings];
	NSParameterAssert(bindings);
	for(NSString* binding in bindings) {
		NSString* keyPath = [NSString stringWithFormat:@"%@.%@",PGDialogKeyPathPrefix,binding];
		[super removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	if([keyPath hasPrefix:PGDialogKeyPathPrefix]==NO) {
		return;
	}
	NSString* key = [keyPath substringFromIndex:([PGDialogKeyPathPrefix length]+1)];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	id newValue = [change objectForKey:NSKeyValueChangeNewKey];
	if([oldValue isNotEqualTo:newValue]) {
		[self valueChangedWithKey:key oldValue:oldValue newValue:newValue];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods
////////////////////////////////////////////////////////////////////////////////

-(void)setViewParameters:(NSDictionary* )parameters {
	NSParameterAssert(parameters);
	[_parameters removeAllObjects];
	[_parameters setValuesForKeysWithDictionary:parameters];
	[self registerBindings];
	
	if([self firstResponder]) {
		[[self firstResponder] becomeFirstResponder];
	}
}

-(void)viewDidEnd {
	[self deregisterBindings];
}

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
#ifdef DEBUG
	NSLog(@"valueChangedWithKey: %@ <'%@' => '%@'>",key,oldValue,newValue);
#endif
}


@end
