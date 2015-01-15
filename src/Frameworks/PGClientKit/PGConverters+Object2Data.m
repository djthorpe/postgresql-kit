
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

#import "PGConverters.h"
#import "PGConverters+Private.h"

////////////////////////////////////////////////////////////////////////////////

NSData* _obj2bin_text(id obj,NSUInteger* type,NSStringEncoding encoding) {
	// TODO
	return nil;
}

NSData* _obj2bin_data(id obj,NSUInteger* type,NSStringEncoding encoding) {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSData class]]);
	NSData* data = (NSData* )obj;
	(*type) = PGOidTypeData;
	return data;
}

////////////////////////////////////////////////////////////////////////////////

@interface NSString (PGConverters)

@end

/*
+(NSData* )obj2data:(id)obj type:(NSUInteger* )oid {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSString class]]);
	NSData* data = [(NSString* )obj dataUsingEncoding:encoding];
	(*type) = PGOidTypeText;
	return data;
}

+(NSData* )obj2text:(id)obj type:(NSUInteger* )oid {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSString class]]);


@end
 */

/*
const void* _obj2bin_number(id obj,NSUInteger* type,NSUInteger* size,BOOL* freeWhenDone,NSStringEncoding encoding) {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSNumber class]]);
	const char* t = [(NSNumber* )obj objCType];
	switch(t[0]) {
		case 'c':
		case 'C':
		case 'B': // boolean
			(*type) = 16;
			(*size) = 1;
			(*freeWhenDone) = NO;
			return [self remoteDataFromBoolean:[(NSNumber* )theObject boolValue]];
		case 'i': // integer
		case 'l': // long
		case 'S': // unsigned short
			(*type) = 23;
			return [self remoteDataFromInt32:[(NSNumber* )theObject shortValue]];
		case 's':
			(*type) = 21;
			return [self remoteDataFromInt16:[(NSNumber* )theObject shortValue]];
		case 'q': // long long
		case 'Q': // unsigned long long
		case 'I': // unsigned integer
		case 'L': // unsigned long
			(*type) = 20;
			return [self remoteDataFromInt64:[(NSNumber* )theObject longLongValue]];
		case 'f': // float
			(*type) = FLXPostgresOidFloat4;
			return [self remoteDataFromFloat32:[(NSNumber* )theObject floatValue]];
		case 'd': // double
			(*type) = FLXPostgresOidFloat8;
			return [self remoteDataFromFloat64:[(NSNumber* )theObject doubleValue]];
	}
	// we shouldn't get here
	NSCParameterAssert(NO);
	return nil;
}
*/
