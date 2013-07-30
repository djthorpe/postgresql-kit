
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
-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;

@end
