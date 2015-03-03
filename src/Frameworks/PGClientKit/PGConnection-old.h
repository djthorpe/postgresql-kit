
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
  *  The PGConnection class represents a single connection to a remote
  *  PostgreSQL database, either via network or file-based socket. The 
  *  connection class provides methods to test connecting, connecting, 
  *  disconnecting, resetting and executing statements on the remote database.
  *  In the future, it will also provide the ability to be informed on 
  *  notification.
  *
  *  You need to use a run loop in order to use this class, since some processes
  *  occur in the background. A delegate can be implemented which is called on
  *  state changes, connection and errors.
  *
  */

////////////////////////////////////////////////////////////////////////////////
// constants

/**
 *  The default port number used for making PostgreSQL connections
 */
extern NSUInteger PGClientDefaultPort;

/**
 *  The maximum supported port value which is supported
 */
extern NSUInteger PGClientMaximumPort;

/**
 *  The domain string used when returning NSError objects
 */
extern NSString* PGClientErrorDomain;

/**
 *  The userInfo key for the connection URL when returning NSError objects
 */
extern NSString* PGClientErrorURLKey;

/**
 *  The default client character encoding to use (UTF-8)
 */
extern NSString* PGConnectionDefaultEncoding;

////////////////////////////////////////////////////////////////////////////////
// forward declarations

@protocol PGConnectionDelegate;

////////////////////////////////////////////////////////////////////////////////
// PGConnection interface

@interface PGConnection : NSObject {
	void* _connection;
	NSLock* _lock;
	PGConnectionStatus _status;
}

////////////////////////////////////////////////////////////////////////////////
// static methods

/**
 *  Returns an array of URL schemes that can be used to connect to the remote
 *  server
 *
 *  @return An array of valid URL schemes
 */
+(NSArray* )allURLSchemes;

/**
 *  Returns the default URL scheme which can be used to connect to the remote
 *  server
 *
 *  @return The name of the default URL scheme
 */
+(NSString* )defaultURLScheme;

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create connection object and connect to remote endpoint in foreground. This
 *  is a convenience method which allocates the PGConnection object, initializes
 *  it, and connects to the remote server all at once. In general, you should
 *  perform these three steps separately.
 *
 *  @param url The endpoint for PostgreSQL server communication
 *  @param error  A pointer to an NSError object
 *
 *  @return Will return a PGConnection reference on successful connection, 
 *          or nil on failure, and return the error via the argument.
 */
+(PGConnection* )connectionWithURL:(NSURL* )url error:(NSError** )error;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The currently set delegate
 */
@property (weak, nonatomic) id<PGConnectionDelegate> delegate;

/**
 *  Tag for the connection object. You can use this in order to refer to the
 *  connection by unique tag number, when implementing a pool of connections
 */
@property NSInteger tag;

/**
 *  Connection timeout in seconds
 */
@property NSUInteger timeout;

/**
 *  The currently connected user, or nil if a connection has not yet been made
 */
@property (readonly) NSString* user;

/**
 *  The currently connected database, or nil if no database has been selected
 */
@property (readonly) NSString* database;

/**
 *  The current database connection status
 */
@property (readonly) PGConnectionStatus status;

/**
 *  The current server process ID
 */
@property (readonly) int serverProcessID;

////////////////////////////////////////////////////////////////////////////////
// connection, ping and disconnection methods

/**
 *  Connect to a database (as specififed by the URL) in the current thread.
 *  Once the connection process is completed (either to successful or unsuccessful
 *  completion, the callback block is run. The error condition is set to nil on
 *  successful connection, or to an error condition on failure.
 *
 *  @param url      The specification of the database that should be connected to
 *  @param callback The callback which is called on conclusion of the connection
 *                  process. The error will be set when the connection fails, or
 *                  else the error is set to nil. A boolean flag indicates if the
 *                  password was used to connect to the remote server.
 */
-(void)connectWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback;

/**
 *  Connect to a database (as specififed by the URL) on a background thread.
 *  Once the connection process is completed (either to successful or unsuccessful
 *  completion, the callback block is run. The error condition is set to nil on
 *  successful connection, or to an error condition on failure.
 *
 *  @param url      The specification of the database that should be connected to
 *  @param callback The callback which is called on conclusion of the connection
 *                  process. The error will be set when the connection fails, or
 *                  else the error is set to nil. A boolean flag indicates if the
 *                  password was used to connect to the remote server.
 */
-(void)connectInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(BOOL usedPassword,NSError* error)) callback;

/**
 *  Pings a remote database to determine if a connect can be initiated. Note
 *  that this method doesn't check credentials, only that a connection could be
 *  initiated. Thus this routine could be used to determine if the URL parameters
 *  are right or not. For example, no attempt to made to check the username,
 *  password or database parameters.
 *
 *  @param url      The specification of the database that should be pinged
 *  @param callback The callback which is called on conclusion of the ping
 *                  process. The error will be set when the connection fails, or
 *                  else the error is set to nil.
 */
-(void)pingWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback;

/**
 *  Pings a remote database to determine if a connect can be initiated on a
 *  background thread. Note that this method doesn't check credentials, only 
 *  that a connection could be initiated. Thus this routine could be used to 
 *  determine if the URL parameters are right or not. For example, no attempt 
 *  to made to check the username, password or database parameters.
 *
 *  @param url      The specification of the database that should be pinged
 *  @param callback The callback which is called on conclusion of the ping
 *                  process. The error will be set when the connection fails, or
 *                  else the error is set to nil.
 */
-(void)pingInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback;

/**
 *  Disconnect from the remote connection
 */
-(void)disconnect;

/**
 *  Perform a connection reset (reconnect with all the same parameters) in the
 *  foreground.
 *
 *  @param callback The callback which is called on conclusion of the reset
 *                  process. The error will be set when the reset fails, or
 *                  else the error is set to nil.
 */
-(void)resetWhenDone:(void(^)(NSError* error)) callback;

/**
 *  Perform a connection reset (reconnect with all the same parameters) in the
 *  background.
 *
 *  @param callback The callback which is called on the main thread on 
 *                  conclusion of the reset process. The error will be set when
 *                  the reset fails, or else the error is set to nil.
 */
-(void)resetInBackgroundWhenDone:(void(^)(NSError* error)) callback;

////////////////////////////////////////////////////////////////////////////////
// listen for notifications

//-(BOOL)addObserver:(NSString* )channelName;
//-(BOOL)removeObserver:(NSString* )channelName;

////////////////////////////////////////////////////////////////////////////////
// execute statement methods

//-(PGQuery* )prepare:(id)query error:(NSError** )error;
-(PGResult* )execute:(id)query error:(NSError** )error;

/*
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format value:(id)value error:(NSError** )error;
-(PGResult* )execute:(NSString* )query error:(NSError** )error;
-(PGResult* )execute:(NSString* )query values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query value:(id)value error:(NSError** )error;
*/

@end

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate protocol

@protocol PGConnectionDelegate <NSObject>
@optional
-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary;
-(void)connection:(PGConnection* )connection willExecute:(NSString* )theQuery values:(NSArray* )values;
-(void)connection:(PGConnection* )connection error:(NSError* )theError;
-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status;
-(void)connection:(PGConnection* )connection notificationOnChannel:(NSString* )channelName payload:(NSString* )payload;
@end

