
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

@implementation PGConnection (Notifications)

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - notifications
////////////////////////////////////////////////////////////////////////////////

-(BOOL)_executeObserverCommand:(NSString* )command channel:(NSString* )channelName {
	NSParameterAssert(command);
	NSParameterAssert(channelName);

	NSString* query = [NSString stringWithFormat:@"%@ %@",command,[self quoteIdentifier:channelName]];
	PGresult* theResult = PQexec(_connection,[query UTF8String]);
	if(theResult==nil) {
		return NO;
	}
	if(PQresultStatus(theResult)==PGRES_BAD_RESPONSE || PQresultStatus(theResult)==PGRES_FATAL_ERROR) {
		PQclear(theResult);
		return NO;
	}
	PQclear(theResult);
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - notifications
////////////////////////////////////////////////////////////////////////////////

-(BOOL)addNotificationObserver:(NSString* )channelName {
	if(_connection == nil || _state != PGConnectionStateNone) {
		return NO;
	}
	return [self _executeObserverCommand:@"LISTEN" channel:channelName];
}

-(BOOL)removeNotificationObserver:(NSString* )channelName {
	if(_connection == nil || _state != PGConnectionStateNone) {
		return NO;
	}
	return [self _executeObserverCommand:@"UNLISTEN" channel:channelName];
}

@end


