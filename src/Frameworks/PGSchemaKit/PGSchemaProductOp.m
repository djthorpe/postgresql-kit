
#import "PGSchemaProductOp.h"

////////////////////////////////////////////////////////////////////////////////
// private method declarations

@interface PGSchemaProductOp (Private)
-(BOOL)_initWithXMLNode:(NSXMLElement* )node;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProductOp

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithXMLNode:(NSXMLElement* )node schema:(NSString* )schema {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		_name = nil;
		_operation = 0;
		_cdata = nil;
		_schema = schema;
		if([self _initWithXMLNode:node]==NO) {
			return nil;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name= _name;
@synthesize schema = _schema;
@synthesize cdata = _cdata;

////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ operation=\"%@\" name=\"%@\">",NSStringFromClass([self class]),[self operation],[self name]];
}


////////////////////////////////////////////////////////////////////////////////
// private methods

+(NSDictionary* )_lookup {
	return @{
	  @"create-table": [NSNumber numberWithInteger:PGSchemaOpCreateTable]
	};
}

-(BOOL)_initWithXMLNode:(NSXMLElement* )node {
	
	// set operation from node name
	_operation = [node name];
	
	// get name of database object
	NSString* nameString =
		[[[node attributeForName:@"name"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(nameString==nil) {
		return nil;
	}
	_name = nameString;
	
	// get cdata part
	_cdata = [node stringValue];
	
	// success
	return YES;
}


@end
