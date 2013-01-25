
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

void _paramFree(PGClientParams* params) {
	free(params->values);
	free(params->types);
	free(params->lengths);
	free(params->formats);
	free(params);
}

PGClientParams* _paramAllocForValues(NSArray* values) {
	PGClientParams* params = malloc(sizeof(PGClientParams));
	if(params==nil) {
		return nil;
	}
	params->size = [values count];
	params->values = nil;
	params->types = nil;
	params->lengths = nil;
	params->formats = nil;	
	if(params->size) {
		params->values = malloc(sizeof(void* ) * params->size);
		params->types = malloc(sizeof(Oid) * params->size);
		params->lengths = malloc(sizeof(int) * params->size);
		params->formats = malloc(sizeof(int) * params->size);
		if(params->values==nil || params->types==nil || params->lengths==nil || params->formats==nil) {
			_paramFree(params);
			return nil;
		}
	}
	return params;
}

void _paramSetNull(PGClientParams* params,NSUInteger i) {
	assert(params);
	assert(i < params->size);
	params->values[i] = nil;
	params->types[i] = 0;
	params->lengths[i] = 0;
	params->formats[i] = 0;
}

void _paramSetData(PGClientParams* params,NSUInteger i,NSData* data,Oid pgtype,int format) {
	assert(params);
	assert(i < params->size);
	assert(data);
	assert([data length] < ((NSUInteger)INT_MAX));
	params->values[i] = [data bytes];
	params->types[i] = pgtype;
	params->lengths[i] = (int)[data length];
	params->formats[i] = format;
}