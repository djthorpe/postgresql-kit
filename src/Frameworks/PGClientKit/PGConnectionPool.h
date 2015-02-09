
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

// forward declarations
@protocol PGConnectionPoolDelegate;

// PGConnectionPool interface
@interface PGConnectionPool : NSObject <PGConnectionDelegate> {
	NSMutableDictionary* _connection;
	NSMutableDictionary* _url;
	PGPasswordStore* _passwd;
	BOOL _useKeychain;
}

// properties
@property (weak, nonatomic) id<PGConnectionPoolDelegate> delegate;
@property PGPasswordStore* passwordStore;
@property BOOL useKeychain;
@property NSArray* connections;

// methods
-(PGConnection* )createConnectionWithURL:(NSURL* )url tag:(NSInteger)tag;
-(void)setURL:(NSURL* )url forTag:(NSInteger)tag;
-(NSURL* )URLForTag:(NSInteger)tag;
-(BOOL)connectWithTag:(NSInteger)tag whenDone:(void(^)(NSError* error)) callback;
-(BOOL)disconnectWithTag:(NSInteger)tag;
-(PGConnectionStatus)statusForTag:(NSInteger)tag;
-(BOOL)removeWithTag:(NSInteger)tag;
-(void)removeAll;
-(void)execute:(NSString* )query forTag:(NSInteger)tag;

@end

// delegate for PGConnectionPool
@protocol PGConnectionPoolDelegate <NSObject>

@optional
	-(void)connectionPool:(PGConnectionPool* )pool tag:(NSInteger)tag statusChanged:(PGConnectionStatus)status;
	-(void)connectionPool:(PGConnectionPool* )pool tag:(NSInteger)tag error:(NSError* )error;

@end

