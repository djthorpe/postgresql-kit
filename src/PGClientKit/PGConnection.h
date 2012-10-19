
#import <Foundation/Foundation.h>

// forward declarations
@protocol PGClientDelegate;

// constants
extern NSString* PGConnectionBonjourServiceType;

// typedefs
typedef enum {
	PGConnectionStatusDisconnected = 0,
	PGConnectionStatusBad = -1,
	PGConnectionStatusRejected = -2,
	PGConnectionStatusConnected = 1
} PGConnectionStatus;

@interface PGClient : NSObject {
	void* _connection;
}

// static methods
+(NSString* )defaultURLScheme;

// properties
@property (weak, nonatomic) id <PGClientDelegate> delegate;
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
-(PGResult* )execute:(NSString* )theQuery error:(NSError** )theError;

@end

// delegate for PGClient
@protocol PGClientDelegate <NSObject>
@optional
-(NSString* )connection:(PGClient* )theConnection passwordForParameters:(NSDictionary* )theParameters;
-(void)connection:(PGClient* )theConnection notice:(NSString* )theMessage;
@end

