
#import <Foundation/Foundation.h>

// externs
extern NSString* PGSchemaErrorDomain;

// typedefs
typedef enum {
	PGSchemaErrorMissingDTD = 100,
	PGSchemaErrorParse = 101
} PGSchemaErrorType;

// forward class declarations
@class PGSchemaProduct;

// header includes
#import "PGSchemaProduct.h"

