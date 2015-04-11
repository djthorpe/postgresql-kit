
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

/**
 *  PGConnectionPool gathers one or more PGConnection objects together, to
 *  co-ordinate the process of connecting to remote PostgreSQL servers. With
 *  a pool instance, the ability to connect, disconnect and query remote servers
 *  in a background thread is provided, and integration with PGPasswordStore
 *  provides the facility to automatically store passwords encrypted in the
 *  users' keychain.
 */

// forward declarations
@protocol PGConnectionPoolDelegate;

////////////////////////////////////////////////////////////////////////////////
// PGConnectionPool interface

@interface PGConnectionPool : NSObject <PGConnectionDelegate> {
	int _type;
	NSMutableDictionary* _connection;
	NSMutableDictionary* _url;
	PGPasswordStore* _passwords;
	BOOL _useKeychain;
}

////////////////////////////////////////////////////////////////////////////////
// constructor

/**
 *  Return a shared pool instance, which provides one connection per tag. This
 *  method should always return the same instance each time it is called.
 *
 *  @return Returns the connection pool instance
 */
+(instancetype)sharedPool;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The connection delegate, which implements methods described in the
 *  PGConnectionPoolDelegate protocol
 */
@property (weak, nonatomic) id<PGConnectionPoolDelegate> delegate;

/**
 *  Returns a PGPasswordStore object, which is used for storing passwords
 *  for the connections.
 */
@property (retain,readonly) PGPasswordStore* passwords;

/**
 *  Returns all the PGConnection objects which are in use within the pool
 */
@property (retain,readonly) NSArray* connections;

/**
 *  This boolean flag property determines if passwords will be stored and
 *  retrieved from the users' keychain. If set to NO, then passwords will
 *  only be stored temporarily. Defaults to YES
 */
@property BOOL useKeychain;

////////////////////////////////////////////////////////////////////////////////
// methods

/**
 *  Creates a new connection object and sets the URL for the connection. The
 *  connection is keyed against a unique "tag", which is used to refer to the
 *  connection. In the "default" mode of operation, only one connection can be
 *  set per tag.
 *
 *  @param url The URL to associate with the connection
 *  @param tag The unique tag used as a key against the connection. Must be a positive
 *             integer.
 *
 *  @return Returns the PGConnection object created, or returns nil if the parameters
 *          provided were incorrect, or the tag is not unique.
 */
-(PGConnection* )createConnectionWithURL:(NSURL* )url tag:(NSInteger)tag;
-(BOOL)connectForTag:(NSInteger)tag whenDone:(void(^)(NSError* error)) callback;
-(BOOL)disconnectForTag:(NSInteger)tag;
-(BOOL)setPassword:(NSString* )password forTag:(NSInteger)tag saveInKeychain:(BOOL)saveInKeychain;
-(BOOL)removePasswordForTag:(NSInteger)tag;
-(BOOL)removeForTag:(NSInteger)tag;
-(BOOL)removeAll;
-(NSURL* )URLForTag:(NSInteger)tag;
-(PGConnection* )connectionForTag:(NSInteger)tag;
-(PGConnectionStatus)statusForTag:(NSInteger)tag;
-(BOOL)execute:(PGTransaction* )transaction forTag:(NSInteger)tag whenDone:(void(^)(PGResult* result,NSError* error)) callback;

@end

// delegate for PGConnectionPool
@protocol PGConnectionPoolDelegate <NSObject>
@optional
-(void)connectionForTag:(NSInteger)tag willOpenWithParameters:(NSMutableDictionary* )parameters;
-(void)connectionForTag:(NSInteger)tag statusChanged:(PGConnectionStatus)status description:(NSString* )description;
-(void)connectionForTag:(NSInteger)tag error:(NSError* )error;
-(void)connectionForTag:(NSInteger)tag notice:(NSString* )notice;
-(void)connectionForTag:(NSInteger)tag notificationOnChannel:(NSString* )channelName payload:(NSString* )payload;
-(NSString* )connectionForTag:(NSInteger)tag willExecute:(NSString* )query;
@end

