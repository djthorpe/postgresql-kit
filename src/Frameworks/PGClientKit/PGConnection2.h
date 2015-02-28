
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

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
// forward declarations

@protocol PGConnectionDelegate2;

////////////////////////////////////////////////////////////////////////////////
// internal state

typedef enum {
	PGConnectionStateNone = 0,
	PGConnectionStateConnect = 100,
	PGConnectionStateQuery = 101
} PGConnectionState;

////////////////////////////////////////////////////////////////////////////////
// PGConnection2 interface

@interface PGConnection2 : NSObject {
	void* _connection;
	void* _callback;
	CFSocketRef _socket;
	CFRunLoopSourceRef _runloopsource;
	NSUInteger _timeout;
	PGConnectionState _state;
}

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The currently set delegate
 */
@property (weak, nonatomic) id<PGConnectionDelegate2> delegate;

/**
 *  The current database connection status
 */
@property (readonly) PGConnectionStatus status;

/**
 *  Connection timeout in seconds
 */
@property NSUInteger timeout;

/**
 *  Tag for the connection object. You can use this in order to refer to the
 *  connection by unique tag number, when implementing a pool of connections
 */
@property NSInteger tag;

/**
 *  The currently connected user, or nil if a connection has not yet been made
 */
@property (readonly) NSString* user;

/**
 *  The currently connected database, or nil if no database has been selected
 */
@property (readonly) NSString* database;

/**
 *  The current server process ID
 */
@property (readonly) int serverProcessID;


////////////////////////////////////////////////////////////////////////////////
// background connection methods

-(void)pingWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback;
-(void)connectWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback;
-(void)disconnect;

////////////////////////////////////////////////////////////////////////////////
// execution methods

-(void)execute:(id)query whenDone:(void(^)(PGResult* result,NSError* error)) callback;

@end

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate protocol

@protocol PGConnectionDelegate2 <NSObject>
@optional
	-(void)connection:(PGConnection2* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary;
	-(void)connection:(PGConnection2* )connection error:(NSError* )theError;
	-(void)connection:(PGConnection2* )connection statusChange:(PGConnectionStatus)status;
	-(void)connection:(PGConnection2* )connection notificationOnChannel:(NSString* )channelName payload:(NSString* )payload;
@end


