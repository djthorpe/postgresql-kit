
@interface FLXPostgresServerAccessTuple : NSObject {
	NSString* comment;
	NSString* type;
	NSString* database;
	NSString* user;	
	NSString* address;	
	NSString* method;	
	NSString* options;	
}

// properties
@property (retain) NSString* comment;
@property (retain) NSString* type;
@property (retain) NSString* database;
@property (retain) NSString* user;	
@property (retain) NSString* address;	
@property (retain) NSString* method;	
@property (retain) NSString* options;	
@property (readonly) BOOL isSuperadminAccess;
@property (readonly) BOOL isAddressEditable;
@property (readonly) BOOL isOptionsEditable;

// constructor
-(id)initWithLine:(NSString* )theLine;

// methods
-(NSString* )asString;

@end
