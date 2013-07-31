
@interface PGSchemaProductOp : NSObject {
	NSDictionary* _attributes;
}

// constructors
+(PGSchemaProductOp* )operationWithXMLNode:(NSXMLElement* )node;
-(id)initWithXMLNode:(NSXMLElement* )node;

// properties
@property (readonly) NSDictionary* attributes;

// methods
-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error;

@end
