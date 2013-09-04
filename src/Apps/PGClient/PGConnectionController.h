
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

// forward declarations
@protocol PGConnectionControllerDelegate;

// PGConnectionController
@interface PGConnectionController : NSObject <PGConnectionDelegate> {
	PGPasswordStore* _passwords;
	NSMutableDictionary* _connections;
	NSMutableDictionary* _urls;
}

// properties
@property (weak, nonatomic) id<PGConnectionControllerDelegate> delegate;

// methods for connections
-(PGConnection* )createConnectionWithURL:(NSURL* )url forKey:(NSUInteger)key;
-(PGConnection* )connectionForKey:(NSUInteger)key;
-(BOOL)openConnectionForKey:(NSUInteger)key;
-(void)closeConnectionForKey:(NSUInteger)key;
-(void)closeAllConnections;
-(NSString* )databaseSelectedForConnectionWithKey:(NSUInteger)key;

// methods for passwords
-(NSString* )passwordForKey:(NSUInteger)key;
-(BOOL)setPassword:(NSString* )password forKey:(NSUInteger)key saveToKeychain:(BOOL)saveToKeychain;


@end

// delegate protocol
@protocol PGConnectionControllerDelegate <NSObject>
@optional
-(void)connectionOpeningWithKey:(NSUInteger)key;
-(void)connectionOpenWithKey:(NSUInteger)key;
-(void)connectionRejectedWithKey:(NSUInteger)key error:(NSError* )error;
-(void)connectionNeedsPasswordWithKey:(NSUInteger)key;
-(void)connectionInvalidPasswordWithKey:(NSUInteger)key;
-(void)connectionClosedWithKey:(NSUInteger)key;
@end

