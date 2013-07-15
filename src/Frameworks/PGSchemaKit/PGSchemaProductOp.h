
#import <Foundation/Foundation.h>

@interface PGSchemaProductOp : NSObject {
	NSString* _operation;
	NSString* _name;
	NSString* _cdata;
}

// constructor
-(id)initWithXMLNode:(NSXMLElement* )node;

// properties
@property (readonly) NSString* name;
@property (readonly) NSString* operation;
@property (readonly) NSString* cdata;

@end
