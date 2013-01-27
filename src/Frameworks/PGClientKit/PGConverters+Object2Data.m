
#import "PGConverters.h"
#import "PGConverters+Private.h"

PGObjectConverterType _pgobject_default_converters[] = {
	{ "NSString", _obj2bin_text, nil },
	{ "NSNumber", _obj2bin_number, nil },
	{ "NSData", _obj2bin_data, nil }
};


#import "PGResult+Converters.h"

////////////////////////////////////////////////////////////////////////////////

const void* _obj2bin_text(id obj,NSUInteger* type,NSUInteger* size,BOOL* freeWhenDone,NSStringEncoding encoding) {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSString class]]);
	NSData* data = [(NSString* )obj dataUsingEncoding:encoding];
	(*type) = 25;
	(*freeWhenDone) = NO;
	(*size) = [data length];
	return [data bytes];
}

const void* _obj2bin_data(id obj,NSUInteger* type,NSUInteger* size,BOOL* freeWhenDone,NSStringEncoding encoding) {
	NSCParameterAssert(obj);
	NSCParameterAssert([obj isKindOfClass:[NSData class]]);
	NSData* data = (NSData* )obj;
	(*type) = 17;
	(*freeWhenDone) = NO;
	(*size) = [data length];
	return [data bytes];
}

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
