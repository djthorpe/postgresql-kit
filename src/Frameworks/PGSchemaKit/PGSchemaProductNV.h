
#import <Foundation/Foundation.h>

@interface PGSchemaProductNV : NSObject {
	NSString* _name;
	NSUInteger _version;
}

// constructor
-(id)initWithXMLNode:(NSXMLElement* )node;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;

@end
