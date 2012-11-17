
@interface FLXPostgresServerIdentityTuple : NSObject <NSCopying> {
	NSString* group;
	NSString* user;	
	NSString* role;	
}

// properties
@property (retain) NSString* group;
@property (retain) NSString* user;	
@property (retain) NSString* role;	
@property (assign) BOOL isSupergroup;

// constructors
-(id)initWithLine:(NSString* )theLine;

// methods
-(NSString* )asString;

@end
