
#import "PGResult+Converters.h"

////////////////////////////////////////////////////////////////////////////////
// binary data

id _bin2obj_data(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	return [NSData dataWithBytesNoCopy:(void* )bytes length:size freeWhenDone:NO];
}

////////////////////////////////////////////////////////////////////////////////
// integers

id _bin2obj_int(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(bytes);
	assert(size);
	assert(size==2 || size==4 || size==8);
	switch(size) {
		case 2:
			return [NSNumber numberWithShort:EndianS16_BtoN(*((SInt16* )bytes))];
		case 4:
			return [NSNumber numberWithInteger:EndianS32_BtoN(*((SInt32* )bytes))];
		case 8:
			return [NSNumber numberWithLongLong:EndianS64_BtoN(*((SInt64* )bytes))];
	}
	return nil;
}

id _bin2obj_uint(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(bytes);
	assert(size);
	assert(size==2 || size==4 || size==8);
	switch(size) {
		case 2:
			return [NSNumber numberWithUnsignedShort:EndianU16_BtoN(*((UInt16* )bytes))];
		case 4:
			return [NSNumber numberWithUnsignedInteger:EndianU32_BtoN(*((UInt32* )bytes))];
		case 8:
			return [NSNumber numberWithUnsignedLongLong:EndianU64_BtoN(*((UInt64* )bytes))];
	}
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// boolean

id _bin2obj_bool(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	NSCParameterAssert(bytes);
	NSCParameterAssert(size==1);
	return [NSNumber numberWithBool:(*((const int8_t* )bytes) ? YES : NO)];
}

////////////////////////////////////////////////////////////////////////////////
// text

id _bin2obj_text(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	return [[NSString alloc] initWithBytes:bytes length:size encoding:encoding];
}

////////////////////////////////////////////////////////////////////////////////
// floats

Float32 _float32FromBytes(const void* theBytes) {
    union { Float32 r; UInt32 i; } u32;
	u32.r = *((Float32* )theBytes);
	u32.i = CFSwapInt32HostToBig(u32.i);
	return u32.r;
}

Float64 _float64FromBytes(const void*  theBytes) {
    union { Float64 r; UInt64 i; } u64;
	u64.r = *((Float64* )theBytes);
	u64.i = CFSwapInt64HostToBig(u64.i);
	return u64.r;
}

id _bin2obj_real(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	NSCParameterAssert(bytes && size);
	NSCParameterAssert(size==4 || size==8);
	switch(size) {
		case 4:
			return [NSNumber numberWithFloat:_float32FromBytes(bytes)];
		case 8:
			return [NSNumber numberWithDouble:_float64FromBytes(bytes)];
	}
	return nil;
}


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

////////////////////////////////////////////////////////////////////////////////
// see postgresql source code for OID definitions
// include/catalog/pg_type.h
// http://doxygen.postgresql.org/include_2catalog_2pg__type_8h.html

PGResultConverterType _pgresult_default_converters[] = {
	{    0, _bin2obj_data, _bin2obj_text,          "default" }, // default converter
	{   16, _bin2obj_bool, _bin2obj_text,          "bool"    },
	{   17, _bin2obj_data, _bin2obj_data,          "data"    },
	{   19, _bin2obj_text, _bin2obj_text,          "name"    },
	{   20, _bin2obj_int,  _bin2obj_text,          "int8"    },
	{   21, _bin2obj_int,  _bin2obj_text,          "int2"    },
	{   23, _bin2obj_int,  _bin2obj_text,          "int4"    },
	{   25, _bin2obj_text, _bin2obj_text,          "text"    },
	{   26, _bin2obj_uint, _bin2obj_text,          "oid"     },
	{  700, _bin2obj_real, _bin2obj_text,          "float4"  },
	{  701, _bin2obj_real, _bin2obj_text,          "float8"  },
	{  705, _bin2obj_text, _bin2obj_text,          "unknown" },
	{ 1042, _bin2obj_text, _bin2obj_text,          "char"    },
	{ 1043, _bin2obj_text, _bin2obj_text,          "varchar" },
	{    0, nil,           nil,                    nil       }  // last entry
};

PGObjectConverterType _pgobject_default_converters[] = {
	{ "NSString", _obj2bin_text, nil },
	{ "NSNumber", _obj2bin_number, nil },
	{ "NSData", _obj2bin_data, nil }
};

////////////////////////////////////////////////////////////////////////////////

PGResultConverterType* _pgresult_cache = nil;
NSUInteger _pgresult_cache_max = 0;

void _pgresult_cache_init() {
	assert(_pgresult_cache==nil);
	assert(_pgresult_cache_max==0);
	PGResultConverterType* t = nil;

	// determine maximum number of entries
	NSUInteger i = 0;
	do {
		t = &(_pgresult_default_converters[i]);
		if(t->oid > _pgresult_cache_max) {
			_pgresult_cache_max = t->oid;
		}
		i++;
	} while(t->name);
#ifdef DEBUG
	NSLog(@"_pgresult_cache_init: allocating %lu entries, %lu bytes for cache",(_pgresult_cache_max+1),sizeof(PGResultConverterType) * (_pgresult_cache_max+1));
#endif
	_pgresult_cache = malloc((_pgresult_cache_max+1) * sizeof(PGResultConverterType));
	assert(_pgresult_cache);
	// make it all zero
	memset(_pgresult_cache,0,(_pgresult_cache_max+1) * sizeof(PGResultConverterType));
	// now copy contents across
	NSUInteger j = 0;
	do {
		t = &(_pgresult_default_converters[j]);
		if(t->name) {
			assert(t->oid <= _pgresult_cache_max);
#ifdef DEBUG
			//NSLog(@"registering oid %lu => %s",t->oid,t->name);
#endif
			memcpy(_pgresult_cache + t->oid,t,sizeof(PGResultConverterType));
		}
		j++;
	} while(t->name);	
}

void _pgresult_cache_destroy() {
#ifdef DEBUG
	NSLog(@"_pgresult_cache_destroy");
#endif
	free(_pgresult_cache);
	_pgresult_cache_max = 0;
}

PGResultConverterType* _pgresult_cache_fetch(NSUInteger oid) {
	assert(_pgresult_cache);
	// return default if not found in cache
	if(oid > _pgresult_cache_max) {
#ifdef DEBUG
		NSLog(@"No type convertors for oid=%lu, using default",oid);
#endif
		return _pgresult_cache;
	}
	PGResultConverterType* t = _pgresult_cache + oid;
	if(t->oid==0) {
#ifdef DEBUG
		NSLog(@"No type convertors (2) for oid=%lu, using default",oid);
#endif
		return _pgresult_cache;
	}
	return t;
}

id _pgresult_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(oid && bytes && size);
	PGResultConverterType* t = _pgresult_cache_fetch(oid);
	assert(t && t->bin2obj);
	return (t->bin2obj)(oid,bytes,size,encoding);
}

id _pgresult_text2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(oid && bytes && size);
	PGResultConverterType* t = _pgresult_cache_fetch(oid);
	assert(t && t->text2obj);
	return (t->text2obj)(oid,bytes,size,encoding);
}

////////////////////////////////////////////////////////////////////////////////

static NSUInteger _pgresult_cache_counter_pgconnection = 0;

void _pgresult_cache_init_pgconnection() {
	_pgresult_cache_counter_pgconnection++;
	if(_pgresult_cache==nil) {
		_pgresult_cache_init();
	}
}

void _pgresult_cache_destroy_pgconnection() {
	_pgresult_cache_counter_pgconnection--;
	if(_pgresult_cache_counter_pgconnection==0 && _pgresult_cache) {
		_pgresult_cache_destroy();
	}
}
