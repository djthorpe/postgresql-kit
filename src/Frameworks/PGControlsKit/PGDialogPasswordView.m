
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

@implementation PGDialogPasswordView

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@dynamic password;
@dynamic saveInKeychain;

-(NSString* )windowTitle {
	return @"Enter Password";
}

-(NSString* )windowDescription {
	return @"If you wish to save your password for future sessions, click \"Save in Keychain\"";
}

-(NSArray* )bindings {
	return @[ @"password",@"save_in_keychain" ];
}

-(NSString* )password {
	return [[self parameters] objectForKey:@"password"];
}

-(BOOL)saveInKeychain {
	NSNumber* saveInKeychain = [[self parameters] objectForKey:@"save_in_keychain"];
	if(saveInKeychain && [saveInKeychain isKindOfClass:[NSNumber class]]) {
		return [saveInKeychain boolValue];
	} else {
		return NO;
	}
}

/**
 *  Method to message the delegate to enable or disable the OK button
 */
-(void)setEnabled:(BOOL)enabled {
	int flag = enabled ? PGDialogWindowFlagEnabled : PGDialogWindowFlagDisabled;
	if([[self delegate] respondsToSelector:@selector(view:setFlags:description:)]) {
		[[self delegate] view:self setFlags:flag description:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];
	
	// if default port checkbox clicked, then set the value in the 'port' field
	if([key isEqualTo:@"password"]) {
		if([[self password] length]) {
			[self setEnabled:YES];
		} else {
			[self setEnabled:NO];
		}
	}
}


@end
