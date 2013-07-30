
@interface PGSchemaManager : NSObject {
	PGConnection* _connection;
	NSString* _sysschema;
	NSString* _usrschema;
	NSMutableArray* _searchpath;
	NSMutableDictionary* _products;
}

// constructor
-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema systemSchema:(NSString* )sysschema;
-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema;

// properties
@property (readonly) NSString* systemSchema;
@property (readonly) NSString* userSchema;
@property (readonly) NSArray* products;
@property (readonly) PGConnection* connection;

// methods
+(NSArray* )defaultSearchPath;
-(BOOL)addSearchPath:(NSString* )path error:(NSError** )error;
-(BOOL)addSearchPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;
-(BOOL)create:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)update:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)drop:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
@end
