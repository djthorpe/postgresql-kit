
#import "PGSchemaProductOp.h"

////////////////////////////////////////////////////////////////////////////////
// private method declarations

@interface PGSchemaProductOp (Private)
-(BOOL)_initWithXMLNode:(NSXMLElement* )node error:(NSError** )error;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProductOp

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithXMLNode:(NSXMLElement* )node error:(NSError** )error {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		_name = nil;
		_operation = nil;
		_cdata = nil;
		if([self _initWithXMLNode:node error:error]==NO) {
			return nil;
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name= _name;

////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ operation=\"%@\" name=\"%@\">",NSStringFromClass([self class]),[self operation],[self name]];
}


////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)_initWithXMLNode:(NSXMLElement* )node error:(NSError** )error {
	
	// set operation from node name
	_operation = [node name];
	
	// get name of database object
	NSString* nameString =
		[[[node attributeForName:@"name"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(nameString==nil) {
		// TODO: raise error
		NSLog(@"error = %@",node);
		return nil;
	}
	_name = nameString;
	
	// get cdata part
	_cdata = [node stringValue];
	
	// success
	return YES;
}

@end
