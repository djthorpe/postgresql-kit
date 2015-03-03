
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

@implementation PGConnection (Cancel)

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - cancelling queries
////////////////////////////////////////////////////////////////////////////////

-(BOOL)_cancelCreate {
	NSParameterAssert(_cancel==nil);
	NSParameterAssert(_connection);
	_cancel = PQgetCancel(_connection);
	return (_cancel==nil) ? NO : YES;
}

-(void)_cancelDestroy {
	if(_cancel) {
		PQfreeCancel(_cancel);
		_cancel = nil;
	}
}

-(void)_cancelRequestInBackgroundCallback:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==2);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSParameterAssert(callback);
	NSError* error = [parameters objectAtIndex:1];
	NSParameterAssert([error isKindOfClass:[NSError class]]);
	NSParameterAssert([[error domain] isEqualToString:PGClientErrorDomain]);

	// set state and destroy cancel object
	[self setState:PGConnectionStateNone];
	[self _cancelDestroy];

	if([error code]==PGClientErrorNone) {
		callback(nil);
	} else {
		callback(error);
	}
}

-(void)_cancelRequestInBackground:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==1);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSParameterAssert(callback);
	NSParameterAssert(_connection);
	NSParameterAssert(_cancel);
	NSParameterAssert([self state]==PGConnectionStateCancel);
	const int bufferLength = 512;
	NSMutableData* buffer = [NSMutableData dataWithCapacity:bufferLength];
	NSParameterAssert(buffer);
	[buffer resetBytesInRange:NSMakeRange(0,[buffer length])];
	int returnValue = PQcancel(_cancel,(char* )[buffer mutableBytes],bufferLength);
	NSError* error = nil;
	if(returnValue==0) {
		// failure to cancel
		NSString* reason = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
		error = [self raiseError:nil code:PGClientErrorExecute reason:reason];
	} else {
		// no error condition
		error = [self raiseError:nil code:PGClientErrorNone];
	}

	// operate callback here on separate thread
	[self performSelector:@selector(_cancelRequestInBackgroundCallback:) onThread:[NSThread mainThread] withObject:@[ callback, error ] waitUntilDone:NO];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - cancelling queries
////////////////////////////////////////////////////////////////////////////////

-(void)cancelWhenDone:(void(^)(NSError* error)) callback {
	NSParameterAssert(callback);
	if(_connection==nil) {
		callback([self raiseError:nil code:PGClientErrorState]);
		return;
	}
	
	// we require state to not be in the connect or reset state
	if([self state]==PGConnectionStateConnect || [self state]==PGConnectionStateReset) {
		callback([self raiseError:nil code:PGClientErrorState]);
		return;
	}

	// try and create the cancel data structure
	if(_cancel==nil) {
		if([self _cancelCreate]==NO) {
			callback([self raiseError:nil code:PGClientErrorParameters]);
			return;
		}
	}

	// change state to cancel
	[self setState:PGConnectionStateCancel];

	// in the background, perform the cancel so we are non-blocking
	[self performSelectorInBackground:@selector(_cancelRequestInBackground:) withObject:@[
		callback
	]];
}

@end


