
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

// externs
extern NSString* PGSchemaErrorDomain;
extern NSString* PGSchemaFileExtension;

// typedefs
typedef enum {
	PGSchemaErrorMissingDTD = 100,
	PGSchemaErrorParse = 101,
	PGSchemaErrorSearchPath = 102,
	PGSchemaErrorDependency = 103,
	PGSchemaErrorDatabase = 104
} PGSchemaErrorType;

// forward class declarations
@class PGSchemaProduct;
@class PGSchema;

// header includes
#import "PGSchema.h"
#import "PGSchemaProduct.h"

