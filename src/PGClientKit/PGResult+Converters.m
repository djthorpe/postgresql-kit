
#import "PGResult+Converters.h"

////////////////////////////////////////////////////////////////////////////////
// see postgresql source code
// include/server/catalog/pg_type.h
// http://doxygen.postgresql.org/include_2catalog_2pg__type_8h-source.html
/*
enum {
	FLXPostgresOidBool = 16,
	FLXPostgresOidData = 17,
	FLXPostgresOidName = 19,
	FLXPostgresOidInt8 = 20,
	FLXPostgresOidInt2 = 21,
	FLXPostgresOidInt4 = 23,
	FLXPostgresOidText = 25,
	FLXPostgresOidOid = 26,
	FLXPostgresOidXML = 142,
	FLXPostgresOidPoint = 600,
	FLXPostgresOidLSeg = 601,
	FLXPostgresOidPath = 602,
	FLXPostgresOidBox = 603,
	FLXPostgresOidPolygon = 604,
	FLXPostgresOidFloat4 = 700,
	FLXPostgresOidFloat8 = 701,
	FLXPostgresOidAbsTime = 702,
	FLXPostgresOidUnknown = 705,
	FLXPostgresOidCircle = 718,
	FLXPostgresOidMoney = 790,
	FLXPostgresOidMacAddr = 829,
	FLXPostgresOidIPAddr = 869,
	FLXPostgresOidNetAddr = 869,
	FLXPostgresOidArrayBool = 1000,
	FLXPostgresOidArrayData = 1001,
	FLXPostgresOidArrayChar = 1002,
	FLXPostgresOidArrayName = 1003,
	FLXPostgresOidArrayInt2 = 1005,
	FLXPostgresOidArrayInt4 = 1007,
	FLXPostgresOidArrayText = 1009,
	FLXPostgresOidArrayVarchar = 1015,
	FLXPostgresOidArrayInt8 = 1016,
	FLXPostgresOidArrayFloat4 = 1021,
	FLXPostgresOidArrayFloat8 = 1022,
	FLXPostgresOidArrayMacAddr = 1040,
	FLXPostgresOidArrayIPAddr = 1041,
	FLXPostgresOidChar = 1042,
	FLXPostgresOidVarchar = 1043,
	FLXPostgresOidDate = 1082,
	FLXPostgresOidTime = 1083,
	FLXPostgresOidTimestamp = 1114,
	FLXPostgresOidTimestampTZ = 1184,
	FLXPostgresOidInterval = 1186,
	FLXPostgresOidTimeTZ = 1266,
	FLXPostgresOidBit = 1560,
	FLXPostgresOidVarbit = 1562,
	FLXPostgresOidNumeric = 1700,
	FLXPostgresOidMax = 1700
};
*/

id _bin2obj_data(NSUInteger oid,const void* bytes,NSUInteger size) {
	return [NSData dataWithBytesNoCopy:(void* )bytes length:size];
}

id _bin2obj_bool(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_name(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_int8(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_int2(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_int4(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_text(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_oid(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_float4(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_float8(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_char(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

id _bin2obj_varchar(NSUInteger oid,const void* bytes,NSUInteger size) {
	return nil;
}

PGResultConverterType _pgresult_default_converters[] = {
	{    0, _bin2obj_data,     nil,          "default" }, // default converter
/*	{   16, _bin2obj_bool,     nil,          "bool"    },
	{   17, _bin2obj_data,     nil,          "data"    },
	{   19, _bin2obj_name,     nil,          "name"    },
	{   20, _bin2obj_int8,     nil,          "int8"    },
	{   21, _bin2obj_int2,     nil,          "int2"    },
	{   23, _bin2obj_int4,     nil,          "int4"    },
	{   25, _bin2obj_text,     nil,          "text"    },
	{   26, _bin2obj_oid,      nil,          "oid"     },
	{   700, _bin2obj_float4,  nil,          "float4"  },
	{   701, _bin2obj_float8,  nil,          "float8"  },
	{  1042, _bin2obj_char,    nil,          "char"    },
	{  1043, _bin2obj_varchar, nil,          "varchar" }, */
	{     0, nil,              nil,          nil       }  // last entry
};

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
	NSLog(@"_pgresult_cache_init: allocating %lu entries, %lu bytes for cache",_pgresult_cache_max,sizeof(PGResultConverterType) * (_pgresult_cache_max+1));
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
		return _pgresult_cache;
	}
	PGResultConverterType* t = _pgresult_cache + oid;
	return t->oid ? t : _pgresult_cache;
}

id _pgresult_bin2obj(NSUInteger oid,const void* bytes,NSUInteger size) {
	assert(oid && bytes && size);
	PGResultConverterType* t = _pgresult_cache_fetch(oid);
	assert(t);
	assert(t->bin2obj);	
	return (t->bin2obj)(oid,bytes,size);
}



