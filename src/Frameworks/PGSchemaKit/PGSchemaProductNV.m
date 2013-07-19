
#import "PGSchemaProductNV.h"

@implementation PGSchemaProductNV

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithName:(NSString* )name version:(NSUInteger)version {
	NSParameterAssert(name);
	NSParameterAssert(version > 0);
	self = [super init];
	if(self) {
		_name = name;
		_version = version;
	}
	return self;	
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
@dynamic key;

-(NSString* )key {
	return [NSString stringWithFormat:@"%@,%lu",[self name],[self version]];
}

////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ name=\"%@\" version=\"%lu\">",NSStringFromClass([self class]),[self name],[self version]];
}

@end
