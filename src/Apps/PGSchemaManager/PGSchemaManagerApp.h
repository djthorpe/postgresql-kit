
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Cocoa.h>
#import <PGSchemaKit/PGSchemaKit.h>

@interface PGSchemaManagerApp : NSObject <NSApplicationDelegate,PGLoginDelegate> {
	PGConnection* _connection;
	PGLoginController* _logincontroller;
	PGSchema* _schema;
}

// properties
@property (assign) IBOutlet NSWindow* window;
@property (readonly) PGLoginController* logincontroller;
@property (readonly) PGConnection* connection;
@property (readonly) PGSchema* schema;
@property (readonly) NSArray* schemas;
@property (readonly) BOOL ibCanLogin;
@property (readonly) BOOL ibCanLogout;

// methods
-(void)addSchemaPath:(NSString* )path;

// actions
-(IBAction)doLogin:(id)sender;

@end
