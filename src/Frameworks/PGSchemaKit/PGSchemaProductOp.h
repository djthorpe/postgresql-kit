
typedef enum {
	PGSchemaProductOpCreate,
	PGSchemaProductOpUpdate,
	PGSchemaProductOpDrop
} 	PGSchemaProductOpType;

@interface PGSchemaProductOp : NSObject {
	NSString* _name;
	NSString* _cdata;
	NSDictionary* _attributes;
}

// constructors
+(PGSchemaProductOp* )operationWithXMLNode:(NSXMLElement* )node;
-(id)initWithXMLNode:(NSXMLElement* )node;

// properties
@property (readonly) NSString* name;
@property (readonly) NSString* cdata;
@property (readonly) NSDictionary* attributes;

// methods
-(BOOL)executeWithConnection:(PGConnection* )connection type:(PGSchemaProductOpType)type dryrun:(BOOL)isDryrun error:(NSError** )error;

@end
