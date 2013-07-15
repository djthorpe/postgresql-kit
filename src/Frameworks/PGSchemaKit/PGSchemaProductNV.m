
#import "PGSchemaProductNV.h"

@implementation PGSchemaProductNV

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		NSString* nameString =
			[[[node attributeForName:@"name"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString* versionString =
			[[[node attributeForName:@"version"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if(nameString==nil || versionString==nil) {
			return nil;
		}
		int versionInt = [versionString intValue];
		if(versionInt <= 0 || [[NSString stringWithFormat:@"%d",versionInt] isEqual:versionString]==NO) {
			return nil;
		}
		_name = nameString;
		_version = (NSUInteger)versionInt;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name= _name;
@synthesize version = _version;

////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ name=\"%@\" version=\"%lu\">",NSStringFromClass([self class]),[self name],[self version]];
}

@end
