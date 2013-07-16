

#import "PGSchemaProductNV.h"
#import "PGSchemaProductOp.h"

@interface PGSchema (Private)
+(NSError* )errorWithCode:(PGSchemaErrorType)code description:(NSString* )description path:(NSString* )path;
-(NSArray* )_scanForSchemasAtPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;
@end
