
#import <Foundation/Foundation.h>

@interface PGClient : NSObject {
	void* _connection;
}

-(BOOL)connectWithURL:(NSURL* )theURL;
-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout;


@end
