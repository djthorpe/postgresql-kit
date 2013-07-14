
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject {
	NSXMLDocument* _document;
}

// constructor
+(PGSchema* )schemaWithPath:(NSString* )path error:(NSError** )error;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;
@property (readonly) NSArray* requires;
@end
