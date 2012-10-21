
#import <Foundation/Foundation.h>

// forward declarations
@protocol PGConnectionDelegate;

@interface PGConnection : NSObject {
	void* _connection;
}

// static methods
+(NSString* )defaultURLScheme;

// properties
@property (weak, nonatomic) id<PGConnectionDelegate> delegate;
@property (readonly) NSString* user;
@property (readonly) NSString* database;
@property (readonly) PGConnectionStatus status;

// connection and discovery of servers
-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )error;
-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error;
-(BOOL)connectInBackgroundWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout whenDone:(void(^)(PGConnectionStatus status,NSError* error)) callback;
-(BOOL)pingWithURL:(NSURL* )theURL error:(NSError** )error;
-(BOOL)pingWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )error;
-(BOOL)disconnect;

// execute statements
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error;
@end

// delegate for PGConnection
@protocol PGConnectionDelegate <NSObject>
@optional
-(NSString* )connectionPasswordForParameters:(NSDictionary* )theParameters;
-(void)connectionWillExecute:(NSString* )theQuery values:(NSArray* )values;
-(void)connectionError:(NSError* )theError;
-(void)connectionNotice:(NSString* )theMessage;
@end

