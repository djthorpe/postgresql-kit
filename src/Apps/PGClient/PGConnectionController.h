
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

@interface PGConnectionController : NSObject {
	NSMutableDictionary* _connections;
	NSMutableDictionary* _urls;
}

// methods
-(PGConnection* )createConnectionWithURL:(NSURL* )url forKey:(NSUInteger)key;
-(PGConnection* )connectionForKey:(NSUInteger)key;
-(BOOL)openConnectionWithKey:(NSUInteger)key;
-(void)closeAllConnections;

@end
