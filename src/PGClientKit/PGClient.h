
#import <Foundation/Foundation.h>

@protocol PGClientDelegate;

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

@end

// delegate for PGClient
@protocol PGClientDelegate <NSObject>
@optional
-(NSString* )connection:(PGClient* )theConnection passwordForParameters:(NSDictionary* )theParameters;
-(void)connection:(PGClient* )theConnection notice:(NSString* )theMessage;
@end

// constants
extern NSString* PGConnectionBonjourServiceType;

