
@interface PGSchemaProductNV : NSObject {
	NSString* _name;
	NSUInteger _version;
}

// constructors
-(id)initWithXMLNode:(NSXMLElement* )node;
-(id)initWithName:(NSString* )name version:(NSUInteger)version;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;
@property (readonly) NSString* key;

@end
