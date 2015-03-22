
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaRootNode = @"product";

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProduct

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path error:(NSError** )error {
	self = [super init];
	if(self) {
		_productnv = nil;
		_requires = nil;
		_comment = nil;
		if([self _initWithPath:path error:error]==NO) {
			return nil;
		}
	}
	return self;
}

+(PGSchemaProduct* )schemaWithPath:(NSString* )path error:(NSError** )error {
	return [[PGSchemaProduct alloc] initWithPath:path error:error];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic name,version,key;
@synthesize comment = _comment;
@synthesize requires = _requires;

-(NSString* )name {
	return [(PGSchemaProductNV* )_productnv name];
}

-(NSUInteger)version {
	return [(PGSchemaProductNV* )_productnv version];
}

-(NSString* )key {
	return [(PGSchemaProductNV* )_productnv key];
}

-(PGSchemaProductNV* )productnv {
	return _productnv;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSXMLDTD* )_dtdWithError:(NSError** )error rootName:(NSString* )rootName {
	NSString* path = [[NSBundle mainBundle] pathForResource:@"pgschema" ofType:@"dtd"];
	if(path==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorMissingDTD description:nil path:nil];
		return nil;
	}
	NSError* xmlerror = nil;
	NSXMLDTD* dtd = [[NSXMLDTD alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:0 error:&xmlerror];
	if(xmlerror) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorMissingDTD description:[xmlerror localizedDescription] path:nil];
		return nil;
	}
	[dtd setName:rootName];
	return dtd;
}

-(NSXMLDocument* )_schemaDocumentWithPath:(NSString* )path error:(NSError** )error {
	NSURL* url = [NSURL fileURLWithPath:path];
	NSError* xmlerror = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&xmlerror];
	if(document==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[xmlerror localizedDescription] path:path];
		return nil;
	}
	// read DTD
	NSXMLDTD* dtd = [self _dtdWithError:error rootName:PGSchemaRootNode];
	if(dtd==nil) {
		return nil;
	}
	// validate document against DTD
	[document setDTD:dtd];
	if([document validateAndReturnError:&xmlerror]==NO) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[xmlerror localizedDescription] path:path];
		return nil;
	}
	
	// success
	return document;
}

-(BOOL)_initWithPath:(NSString* )path error:(NSError** )error {
	NSParameterAssert(path);
	NSError* localerror = nil;
	NSXMLDocument* document = [self _schemaDocumentWithPath:path error:error];
	NSXMLElement* rootNode = [document rootElement];
	if(document==nil) {
		return NO;
	}
	NSParameterAssert(rootNode);

	_productnv = [[PGSchemaProductNV alloc] initWithXMLNode:rootNode];
	if(_productnv==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"invalid name or version on <product> element" path:path];
		return NO;
	}
	
	// get comment statement
	NSArray* comment = [document nodesForXPath:@"//comment" error:&localerror];
	if(comment==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	if([comment count] > 1) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"only one <comment> element is allowed" path:path];
		return NO;		
	}
	if([comment count]==1) {
		_comment = [(NSXMLNode* )[comment objectAtIndex:0] stringValue];
	}
	
	// get requires statements
	NSArray* requires = [document nodesForXPath:@"//requires" error:&localerror];
	if(requires==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_requires = [NSMutableArray arrayWithCapacity:[requires count]];
	for(NSXMLElement* node in requires) {
		PGSchemaProductNV* productnv = [[PGSchemaProductNV alloc] initWithXMLNode:node];
		if(productnv==nil) {
			(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"invalid name or version on <requires> element" path:path];
			return NO;
		}
		[_requires addObject:productnv];
	}
	
	// create statements
	NSArray* create = [document nodesForXPath:@"//create/*" error:&localerror];
	if(create==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_create = [NSMutableArray arrayWithCapacity:[create count]];
	for(NSXMLElement* node in create) {
		PGSchemaProductOp* op = [PGSchemaProductOp operationWithXMLNode:node];
		if(op==nil) {
			(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"invalid operation on <create> element" path:path];
			return NO;
		}
		[_create addObject:op];
	}

	// update statements
	NSArray* update = [document nodesForXPath:@"//update/*" error:&localerror];
	if(update==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_update = [NSMutableArray arrayWithCapacity:[update count]];
	for(NSXMLElement* node in create) {
		PGSchemaProductOp* op = [PGSchemaProductOp operationWithXMLNode:node];
		if(op==nil) {
			(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"invalid operation on <create> element" path:path];
			return NO;
		}
		[_create addObject:op];
	}

	// drop statements
	NSArray* drop = [document nodesForXPath:@"//drop/*" error:&localerror];
	if(drop==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_drop = [NSMutableArray arrayWithCapacity:[drop count]];
	for(NSXMLElement* node in drop) {
		PGSchemaProductOp* op = [PGSchemaProductOp operationWithXMLNode:node];
		if(op==nil) {
			(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorParse description:@"invalid operation on <drop> element" path:path];
			return NO;
		}
		[_drop addObject:op];
	}
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	for(PGSchemaProductOp* op in _create) {
		if([op createWithConnection:connection dryrun:isDryrun error:error]==NO) {
			return NO;
		}
	}
	return YES;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	for(PGSchemaProductOp* op in _update) {
		if([op updateWithConnection:connection dryrun:isDryrun error:error]==NO) {
			return NO;
		}
	}
	return YES;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	for(PGSchemaProductOp* op in _drop) {
		if([op dropWithConnection:connection dryrun:isDryrun error:error]==NO) {
			return NO;
		}
	}
	return YES;	
}


////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ name=\"%@\" version=\"%lu\" requires=%@ create=%@ drop=%@>",NSStringFromClass([self class]),[self name],[self version],
				_requires,_create,_drop];
}

@end


