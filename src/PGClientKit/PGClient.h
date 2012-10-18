
#import <Foundation/Foundation.h>

@protocol PGClientDelegate;

@interface PGClient : NSObject {
	void* _connection;
}

@property (weak, nonatomic) id <PGClientDelegate> delegate;

-(BOOL)connectWithURL:(NSURL* )theURL error:(NSError** )theError;
-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout error:(NSError** )theError;
-(BOOL)disconnect;

@end

// delegate for PGClient
@protocol PGClientDelegate <NSObject>
@optional
-(NSString* )connection:(PGClient* )theConnection passwordForParameters:(NSDictionary* )theParameters;
-(void)connection:(PGClient* )theConnection notice:(NSString* )theMessage;
@end

