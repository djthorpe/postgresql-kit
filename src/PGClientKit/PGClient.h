
#import <Foundation/Foundation.h>

@protocol PGClientDelegate;

// class PGClient
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
-(NSString* )client:(PGClient* )theClient passwordForParameters:(NSDictionary* )theParameters;
@end

