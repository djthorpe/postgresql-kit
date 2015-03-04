
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

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

// keys
NSString* PQSelectTableNameKey = @"PGSelect_table";
NSString* PQSelectSchemaNameKey = @"PGSelect_schema";

// additional option flags
enum {
	PGSelectTableSource = 0x0100000,
};

@implementation PGSelect

+(PGSelect* )selectTableSource:(NSString* )tableName schema:(NSString* )schemaName options:(int)options {
	NSParameterAssert(tableName);
	PGQueryCreate* query = [super queryWithDictionary:@{
		PQQueryClassKey: NSStringFromClass([self class]),
		PQSelectTableNameKey: tableName
	}];
	if(schemaName) {
		[query setObject:schemaName forKey:PQSelectSchemaNameKey];
	}
	[query setOptions:(options | PGSelectTableSource)];
	return query;
}

@end
