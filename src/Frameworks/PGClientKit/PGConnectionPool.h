
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

// PGConnectionPool interface
@interface PGConnectionPool : NSObject <PGConnectionDelegate> {
	int _type;
	NSMutableDictionary* _connection;
	NSMutableDictionary* _url;
	PGPasswordStore* _passwords;
	BOOL _useKeychain;
}

// singleton constructor
+(instancetype)sharedPool;

// properties
@property (weak, nonatomic) id<PGConnectionPoolDelegate> delegate;
@property (retain,readonly) PGPasswordStore* passwords;
@property (retain,readonly) NSArray* connections;
@property BOOL useKeychain;

// methods
-(PGConnection* )createConnectionWithURL:(NSURL* )url tag:(NSInteger)tag;
-(BOOL)connectForTag:(NSInteger)tag whenDone:(void(^)(NSError* error)) callback;
-(BOOL)disconnectForTag:(NSInteger)tag;
-(BOOL)setPassword:(NSString* )password forTag:(NSInteger)tag saveInKeychain:(BOOL)saveInKeychain;
-(BOOL)removePasswordForTag:(NSInteger)tag;
-(BOOL)removeForTag:(NSInteger)tag;
-(BOOL)removeAll;
-(NSURL* )URLForTag:(NSInteger)tag;
-(PGConnectionStatus)statusForTag:(NSInteger)tag;

/*
-(PGResult* )execute:(NSString* )query forTag:(NSInteger)tag;
*/
@end

// delegate for PGConnectionPool
@protocol PGConnectionPoolDelegate <NSObject>
@optional
-(void)connectionForTag:(NSInteger)tag willOpenWithParameters:(NSMutableDictionary* )parameters;
-(void)connectionForTag:(NSInteger)tag statusChanged:(PGConnectionStatus)status description:(NSString* )description;
-(void)connectionForTag:(NSInteger)tag error:(NSError* )error;
-(void)connectionForTag:(NSInteger)tag notice:(NSString* )notice;
-(void)connectionForTag:(NSInteger)tag notificationOnChannel:(NSString* )channelName payload:(NSString* )payload;
-(void)connectionForTag:(NSInteger)tag willExecute:(NSString* )query;
@end

