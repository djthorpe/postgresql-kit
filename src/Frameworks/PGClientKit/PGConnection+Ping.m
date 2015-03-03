
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

@implementation PGConnection (Ping)

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - ping
////////////////////////////////////////////////////////////////////////////////

-(void)_pingInBackgroundCallback:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==2);
	void(^callback)(NSError* error) = [parameters objectAtIndex:0];
	NSParameterAssert(callback);
	NSError* error = [parameters objectAtIndex:1];
	NSParameterAssert([error isKindOfClass:[NSError class]]);
	NSParameterAssert([[error domain] isEqualToString:PGClientErrorDomain]);
	
	if([error code]==PGClientErrorNone) {
		callback(nil);
	} else {
		callback(error);
	}
}

-(void)_pingInBackground:(NSArray* )parameters {
	NSParameterAssert(parameters && [parameters count]==2);
	NSDictionary* dictionary = [parameters objectAtIndex:0];
	NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
	void(^callback)(NSError* error) = [parameters objectAtIndex:1];
	NSParameterAssert(callback);

	@autoreleasepool {
		// make the key value pairs
		PGKVPairs* pairs = makeKVPairs(dictionary);
		NSError* error = nil;
		PGPing status = PQPING_NO_ATTEMPT;
		if(pairs != nil) {
			status = PQpingParams(pairs->keywords,pairs->values,0);
			freeKVPairs(pairs);
		}
		switch(status) {
			case PQPING_OK:
				error = [self raiseError:nil code:PGClientErrorNone];
				break;
			case PQPING_REJECT:
				error = [self raiseError:nil code:PGClientErrorRejected reason:@"Remote server is not accepting connections"];
				break;
			case PQPING_NO_ATTEMPT:
				error = [self raiseError:nil code:PGClientErrorParameters];
				break;
			case PQPING_NO_RESPONSE:
				error = [self raiseError:nil code:PGClientErrorRejected reason:@"No response from remote server"];
				break;
			default:
				error = [self raiseError:nil code:PGClientErrorUnknown reason:@"Unknown ping error (%d)",status];
				break;
		}

		// perform callback on main thread
		[self performSelector:@selector(_pingInBackgroundCallback:) onThread:[NSThread mainThread] withObject:@[ callback, error ] waitUntilDone:NO];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - ping
////////////////////////////////////////////////////////////////////////////////

-(void)pingWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback {
	NSParameterAssert(url);
	NSParameterAssert(callback);

	// extract connection parameters
	NSDictionary* parameters = [self _connectionParametersForURL:url];
	if(parameters==nil) {
		callback([self raiseError:nil code:PGClientErrorParameters]);
		return;
	}

	// in the background, perform the ping
	[self performSelectorInBackground:@selector(_pingInBackground:) withObject:@[
		parameters,callback
	]];
}

@end


