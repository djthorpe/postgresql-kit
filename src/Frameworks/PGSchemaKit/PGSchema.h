
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject

// constructor
+(PGSchema* )schemaWithPath:(NSString* )path error:(NSError** )error;

@end
