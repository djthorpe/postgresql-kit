
@interface PGSchemaProduct : NSObject {
	id _productnv; // returns PGSchemaProductNV*
	NSString* _comment;
	NSMutableArray* _requires; // array of PGSchemaProductNV*
	NSMutableArray* _create; // array of PGSchemaProductOp*
	NSMutableArray* _update; // array of PGSchemaProductOp*
	NSMutableArray* _drop; // array of PGSchemaProductOp*
}

// constructors
-(id)initWithPath:(NSString* )path error:(NSError** )error;
+(PGSchemaProduct* )schemaWithPath:(NSString* )path error:(NSError** )error;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;
@property (readonly) NSString* comment;
@property (readonly) NSArray* requires;
@property (readonly) NSString* key;

// methods
-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;

@end
