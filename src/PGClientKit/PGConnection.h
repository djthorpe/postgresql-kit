
#import <Foundation/Foundation.h>

// forward declarations
@protocol PGConnectionDelegate;

@interface PGConnection : NSObject {
	void* _connection;
}

// static methods
+(NSString* )defaultURLScheme;

// properties
@property (weak, nonatomic) id <PGConnectionDelegate> delegate;
@property (readonly) NSString* user;
@property (readonly) NSString* database;
@property (readonly) PGConnectionStatus status;

// connection and discovery of servers
-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )theError;
-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )theError;
-(BOOL)pingWithURL:(NSURL* )theURL error:(NSError** )theError;
-(BOOL)pingWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )theError;
-(BOOL)disconnect;

// execute statements
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error;
@end

// delegate for PGConnection
@protocol PGConnectionDelegate <NSObject>
@optional
-(NSString* )connection:(PGConnection* )theConnection passwordForParameters:(NSDictionary* )theParameters;
-(void)connection:(PGConnection* )theConnection notice:(NSString* )theMessage;
-(void)connection:(PGConnection* )theConnection willExecute:(NSString* )theQuery values:(NSArray* )values;
@end

