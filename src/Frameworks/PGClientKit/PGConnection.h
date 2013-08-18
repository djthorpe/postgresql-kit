
#import <Foundation/Foundation.h>

// externs
extern NSUInteger PGClientDefaultPort;
extern NSUInteger PGClientMaximumPort;
extern NSString* PGClientErrorDomain;

// forward declarations
@protocol PGConnectionDelegate;

@interface PGConnection : NSObject {
	void* _connection;
}

////////////////////////////////////////////////////////////////////////////////
// static methods

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
 *          or nil on failure, and return the error message via the argument.
 */
+(PGConnection* )connectionWithURL:(NSURL* )url error:(NSError** )error;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The currently set delegate
 */
@property (weak, nonatomic) id<PGConnectionDelegate> delegate;

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

////////////////////////////////////////////////////////////////////////////////
// connection and disconnection methods

-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )error;
-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error;
-(BOOL)connectInBackgroundWithURL:(NSURL* )theURL whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback;
-(BOOL)connectInBackgroundWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback;
-(BOOL)pingWithURL:(NSURL* )theURL error:(NSError** )error;
-(BOOL)pingWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error;
-(BOOL)disconnect;

// execute statements
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format value:(id)value error:(NSError** )error;
-(PGResult* )execute:(NSString* )query error:(NSError** )error;
-(PGResult* )execute:(NSString* )query values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query value:(id)value error:(NSError** )error;

@end

// delegate for PGConnection
@protocol PGConnectionDelegate <NSObject>
@optional
-(NSString* )connectionPasswordForParameters:(NSDictionary* )theParameters;
-(void)connectionWillExecute:(NSString* )theQuery values:(NSArray* )values;
-(void)connectionError:(NSError* )theError;
-(void)connectionNotice:(NSString* )theMessage;
@end

