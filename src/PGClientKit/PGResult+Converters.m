
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
	return nil;
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
	{    0, _bin2obj_data,     nil,          "default" },
	{   16, _bin2obj_bool,     nil,          "bool"    },
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
	{  1043, _bin2obj_varchar, nil,          "varchar" },
	{     0, nil,              nil,          nil       }
};



