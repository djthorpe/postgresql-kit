
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
#import "CoreFoundation/CoreFoundation.h"

////////////////////////////////////////////////////////////////////////////////
// forward declarations

id _bin2obj_data(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _bin2obj_int(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _bin2obj_uint(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _bin2obj_bool(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _bin2obj_text(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);
id _bin2obj_real(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding);

////////////////////////////////////////////////////////////////////////////////
// Lookup table

PGResultConverterType _pgdata2obj_default_converters[] = {
	{                0, _bin2obj_data, _bin2obj_text,          "default" }, // default converter
	{    PGOidTypeBool, _bin2obj_bool, _bin2obj_text,          "bool"    },
	{    PGOidTypeData, _bin2obj_data, _bin2obj_data,          "data"    },
	{    PGOidTypeName, _bin2obj_text, _bin2obj_text,          "name"    },
	{    PGOidTypeInt8, _bin2obj_int,  _bin2obj_text,          "int8"    },
	{    PGOidTypeInt2, _bin2obj_int,  _bin2obj_text,          "int2"    },
	{    PGOidTypeInt4, _bin2obj_int,  _bin2obj_text,          "int4"    },
	{    PGOidTypeText, _bin2obj_text, _bin2obj_text,          "text"    },
	{     PGOidTypeOid, _bin2obj_uint, _bin2obj_text,          "oid"     },
	{     PGOidTypeXid, _bin2obj_uint, _bin2obj_text,          "xid"     },
	{  PGOidTypeFloat4, _bin2obj_real, _bin2obj_text,          "float4"  },
	{  PGOidTypeFloat8, _bin2obj_real, _bin2obj_text,          "float8"  },
	{ PGOidTypeUnknown, _bin2obj_text, _bin2obj_text,          "unknown" },
	{    PGOidTypeChar, _bin2obj_text, _bin2obj_text,          "char"    },
	{  PGOidTypeBPChar, _bin2obj_text, _bin2obj_text,          "char"    },
	{ PGOidTypeVarchar, _bin2obj_text, _bin2obj_text,          "varchar" },
	{                0, nil,           nil,                    nil       }  // last entry
};

////////////////////////////////////////////////////////////////////////////////
// Global variables

PGResultConverterType* _pgdata2obj_cache = nil;
NSUInteger _pgdata2obj_cache_max = 0;
NSUInteger _pgdata2obj_cache_counter = 0;

////////////////////////////////////////////////////////////////////////////////
// Private methods to initialize and free the cache

void _pgdata2obj_cache_init() {
	assert(_pgdata2obj_cache==nil);
	assert(_pgdata2obj_cache_max==0);
	PGResultConverterType* t = nil;
	
	// determine maximum number of entries
	NSUInteger i = 0;
	do {
		t = &(_pgdata2obj_default_converters[i]);
		if(t->oid > _pgdata2obj_cache_max) {
			_pgdata2obj_cache_max = t->oid;
		}
		i++;
	} while(t->name);
#ifdef DEBUG
	NSLog(@"pgdata2obj_cache_init: allocating %lu entries, %lu bytes for cache",(unsigned long)(_pgdata2obj_cache_max+1),sizeof(PGResultConverterType) * (_pgdata2obj_cache_max+1));
#endif
	_pgdata2obj_cache = malloc((_pgdata2obj_cache_max+1) * sizeof(PGResultConverterType));
	assert(_pgdata2obj_cache);
	// make it all zero
	memset(_pgdata2obj_cache,0,(_pgdata2obj_cache_max+1) * sizeof(PGResultConverterType));
	// now copy contents across
	NSUInteger j = 0;
	do {
		t = &(_pgdata2obj_default_converters[j]);
		if(t->name) {
			assert(t->oid <= _pgdata2obj_cache_max);
			memcpy(_pgdata2obj_cache + t->oid,t,sizeof(PGResultConverterType));
		}
		j++;
	} while(t->name);
}

void _pgdata2obj_cache_destroy() {
#ifdef DEBUG
	NSLog(@"_pgresult_cache_destroy");
#endif
	free(_pgdata2obj_cache);
	_pgdata2obj_cache_max = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Public methods to initialize and free the cache

void pgdata2obj_init() {
	_pgdata2obj_cache_counter++;
	if(_pgdata2obj_cache==nil) {
		_pgdata2obj_cache_init();
	}
}

void pgdata2obj_destroy() {
	_pgdata2obj_cache_counter--;
	if(_pgdata2obj_cache_counter==0 && _pgdata2obj_cache) {
		_pgdata2obj_cache_destroy();
	}
}

////////////////////////////////////////////////////////////////////////////////
// Cache lookup

PGResultConverterType* _pgdata2obj_cache_fetch(NSUInteger oid) {
	assert(_pgdata2obj_cache);
	// return default if not found in cache
	if(oid > _pgdata2obj_cache_max) {
#ifdef DEBUG
		NSLog(@"No type convertors for oid=%lu, using default",(unsigned long)oid);
#endif
		return _pgdata2obj_cache;
	}
	PGResultConverterType* t = _pgdata2obj_cache + oid;
	if(t->oid==0) {
#ifdef DEBUG
		NSLog(@"No type convertors (2) for oid=%lu, using default",(unsigned long)oid);
#endif
		return _pgdata2obj_cache;
	}
	return t;
}

id pgdata_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
//	assert(oid && bytes && size);
	assert(oid && bytes);
	PGResultConverterType* t = _pgdata2obj_cache_fetch(oid);
	assert(t && t->bin2obj);
	return (t->bin2obj)(oid,bytes,size,encoding);
}

id pgdata_text2obj(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
//	assert(oid && bytes && size);
	assert(oid && bytes);
	PGResultConverterType* t = _pgdata2obj_cache_fetch(oid);
	assert(t && t->text2obj);
	return (t->text2obj)(oid,bytes,size,encoding);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark binary data
////////////////////////////////////////////////////////////////////////////////

id _bin2obj_data(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	return [NSData dataWithBytesNoCopy:(void* )bytes length:size freeWhenDone:NO];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark integers
////////////////////////////////////////////////////////////////////////////////

id _bin2obj_int(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(bytes);
	assert(size);
	assert(size==2 || size==4 || size==8);
	switch(size) {
		case 2:
			return [NSNumber numberWithShort:(int16_t)CFSwapInt16BigToHost(*((uint16_t* )bytes))];
		case 4:
			return [NSNumber numberWithInteger:(int32_t)CFSwapInt32BigToHost(*((uint32_t* )bytes))];
		case 8:
			return [NSNumber numberWithLongLong:(int64_t)CFSwapInt64BigToHost(*((uint64_t* )bytes))];
	}
	return nil;
}

id _bin2obj_uint(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	assert(bytes);
	assert(size);
	assert(size==2 || size==4 || size==8);
	switch(size) {
		case 2:
			return [NSNumber numberWithUnsignedShort:CFSwapInt16BigToHost(*((uint16_t* )bytes))];
		case 4:
			return [NSNumber numberWithUnsignedInteger:CFSwapInt32BigToHost(*((uint32_t* )bytes))];
		case 8:
			return [NSNumber numberWithUnsignedLongLong:CFSwapInt64BigToHost(*((uint64_t* )bytes))];
	}
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark boolean
////////////////////////////////////////////////////////////////////////////////

id _bin2obj_bool(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	NSCParameterAssert(bytes);
	NSCParameterAssert(size==1);
	return [NSNumber numberWithBool:(*((const int8_t* )bytes) ? YES : NO)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark text
////////////////////////////////////////////////////////////////////////////////

id _bin2obj_text(NSUInteger oid,const void* bytes,NSUInteger size,NSStringEncoding encoding) {
	return [[NSString alloc] initWithBytes:bytes length:size encoding:encoding];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark floats
////////////////////////////////////////////////////////////////////////////////

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

