
#import <Foundation/Foundation.h>

// typedefs
typedef enum {
	PGSchemaOpCreateTable = 100, PGSchemaOpDropTable,
	PGSchemaOpCreateIndex, PGSchemaOpDropIndex,
	PGSchemaOpCreateType, PGSchemaOpDropType,
	PGSchemaOpCreateView, PGSchemaOpDropView,
	PGSchemaOpCreateFunction, PGSchemaOpDropFunction,
	PGSchemaOpCreateTrigger, PGSchemaOpDropTrigger
} PGSchemaOpType;


@interface PGSchemaProductOp : NSObject {
	PGSchemaOpType _operation;
	NSString* _name;
	NSString* _schema;
	NSString* _cdata;
}

// constructor
-(id)initWithXMLNode:(NSXMLElement* )node schema:(NSString* )schema;

// properties
@property (readonly) PGSchemaOpType operation;
@property (readonly) NSString* name;
@property (readonly) NSString* schema;
@property (readonly) NSString* cdata;

@end
