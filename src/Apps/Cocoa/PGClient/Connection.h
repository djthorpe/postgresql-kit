
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

@interface Connection : NSObject <PGConnectionDelegate> {
	PGConnection* _connection;
	PGPasswordStore* _password;
}

// properties
@property (readonly) PGConnection* connection;
@property (readonly) PGPasswordStore* password;
@property BOOL useKeychain;
@property (readonly) NSURL* url;

// methods
-(void)login;
-(void)disconnect;

@end
