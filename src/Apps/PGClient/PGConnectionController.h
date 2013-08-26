
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>
#import <PGControlsKit/PGControlsKit.h>

@interface PGConnectionController : NSObject <PGConsoleViewDelegate> {
	NSMutableDictionary* _connections;
	NSMutableDictionary* _urls;
	NSMutableDictionary* _consoles;
}

// methods
-(PGConnection* )createConnectionWithURL:(NSURL* )url forKey:(NSUInteger)key;
-(PGConnection* )connectionForKey:(NSUInteger)key;
-(BOOL)openConnectionWithKey:(NSUInteger)key;
-(BOOL)closeConnectionForKey:(NSUInteger)key;
-(void)closeAllConnections;
-(PGConsoleView* )consoleForKey:(NSUInteger)key;

@end
