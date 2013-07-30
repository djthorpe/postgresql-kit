
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

const NSDictionary* PGSchemaProductOpLookup = nil;

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProductOp

////////////////////////////////////////////////////////////////////////////////
// private methods

+(void)initialize {
	PGSchemaProductOpLookup = @{
		@"create-table":    @"PGSchemaProductOpTable",
		@"update-table":    @"PGSchemaProductOpTable",
		@"drop-table":      @"PGSchemaProductOpTable",
		@"create-view":     @"PGSchemaProductOpView",
		@"update-view":     @"PGSchemaProductOpView",
		@"drop-view":       @"PGSchemaProductOpView",
		@"create-index":    @"PGSchemaProductOpIndex",
		@"update-index":    @"PGSchemaProductOpIndex",
		@"drop-index":      @"PGSchemaProductOpIndex",
		@"create-type":     @"PGSchemaProductOpType",
		@"update-type":     @"PGSchemaProductOpType",
		@"drop-type":       @"PGSchemaProductOpType",
		@"create-function": @"PGSchemaProductOpFunction",
		@"update-function": @"PGSchemaProductOpFunction",
		@"drop-function":   @"PGSchemaProductOpFunction"
	};
}

////////////////////////////////////////////////////////////////////////////////
// constructor

+(PGSchemaProductOp* )operationWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(PGSchemaProductOpLookup);
	NSParameterAssert(node);
	Class opclass = NSClassFromString([PGSchemaProductOpLookup objectForKey:[node name]]);
	if(!opclass) {
		return nil;
	}
	return [[opclass alloc] initWithXMLNode:node];
}

-(id)init {
	return nil;
}

-(id)initWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		_name = [node name];
		_cdata = [node stringValue];
		_attributes = [NSMutableDictionary dictionaryWithCapacity:[[node attributes] count]];
		for(NSXMLNode* attr in [node attributes]) {
			NSString* key = [attr name];
			if([_attributes objectForKey:key]==nil) {
				// only first attribute of the same name is allowed
				[_attributes setValue:[attr stringValue] forKey:key];
			}
		}
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name= _name;
@synthesize cdata = _cdata;
@synthesize attributes = _attributes;

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"createWithConnection not implemented"];
	return NO;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"updateWithConnection not implemented"];
	return NO;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"dropWithConnection not implemented"];
	return NO;
}

@end
