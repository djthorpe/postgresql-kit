
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject

// constructor
+(PGSchema* )schemaWithPath:(NSString* )path error:(NSError** )error;

// properties
@property (readonly) NSString* name;
@property (readonly) NSUInteger version;
@property (readonly) NSArray* requires;

@end
