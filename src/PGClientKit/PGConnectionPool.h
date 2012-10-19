
#import <Foundation/Foundation.h>
#import "PGClientKit.h"

@interface PGConnectionPool : NSObject <NSNetServiceBrowserDelegate> {
	NSMutableDictionary* _hash;
}

+(PGConnectionPool* )sharedConnectionPool;
-(PGConnection* )connectionForHandle:(const void* )handle;
-(void)addConnection:(PGConnection* )theConnection forHandle:(const void* )handle;
-(void)removeConnectionForHandle:(const void* )handle;
-(void)removeAllConnections;

@end
