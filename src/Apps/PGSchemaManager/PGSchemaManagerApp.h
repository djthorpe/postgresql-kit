
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Cocoa.h>
#import <PGSchemaKit/PGSchemaKit.h>

@interface PGSchemaManagerApp : NSObject <NSApplicationDelegate,PGLoginDelegate,NSTableViewDelegate> {
	PGConnection* _connection;
	PGLoginController* _logincontroller;
	PGSchemaManager* _schema;
	PGSchemaProduct* _selected;
}

// properties
@property (assign) IBOutlet NSWindow* window;
@property (readonly) PGLoginController* logincontroller;
@property (readonly) PGConnection* connection;
@property (readonly) PGSchemaManager* schema;
@property (readonly) NSArray* schemas;
@property (readonly) BOOL ibCanLogin;
@property (readonly) BOOL ibCanLogout;
@property (retain) PGSchemaProduct* selected;

// methods
-(void)addSchemaPath:(NSString* )path;

// actions
-(IBAction)doLogin:(id)sender;
-(IBAction)doLogout:(id)sender;
-(IBAction)doCreate:(id)sender;
-(IBAction)doDrop:(id)sender;
-(IBAction)doAddSearchPath:(id)sender;

@end
