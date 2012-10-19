
#import <Foundation/Foundation.h>
#import "PGClientKit.h"

@interface PGConnectionPool : NSObject <NSNetServiceBrowserDelegate> {
	NSMutableDictionary* _hash;
}

+(PGConnectionPool* )sharedConnectionPool;
-(PGClient* )connectionForHandle:(const void* )handle;
-(void)addConnection:(PGClient* )theConnection forHandle:(const void* )handle;
-(void)removeConnectionForHandle:(const void* )handle;
-(void)removeAllConnections;

@end
