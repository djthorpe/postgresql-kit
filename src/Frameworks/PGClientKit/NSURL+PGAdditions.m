
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

@implementation NSURL (PGAdditions)

+(NSString* )_pg_urlencode:(NSString* )string {
	return (NSString* )CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)string,NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
}

+(NSString* )_pg_urlencode_params:(NSDictionary* )params {
	if(params==nil || [params count]==0) {
		return @"";
	}	
	NSMutableArray* parts = [NSMutableArray arrayWithCapacity:[params count]];
	for(id key in [params allKeys]) {
		if([key isKindOfClass:[NSString class]]==NO) {
			return nil;
		}
		id value = [params objectForKey:key];
		if([value isKindOfClass:[NSObject class]]==NO) {
			return nil;
		}
		NSString* keyenc = [self _pg_urlencode:(NSString* )key];
		NSString* valueenc = [self _pg_urlencode:[(NSObject* )value description]];
		if(keyenc==nil || valueenc==nil) {
			return nil;
		}
		NSString* pair = [NSString stringWithFormat:@"%@=%@",keyenc,valueenc];
		[parts addObject:pair];
	}
	return [@"?" stringByAppendingString:[parts componentsJoinedByString:@"&"]];
}

+(NSString* )_pg_urlencode_database:(NSString* )db {
	if(db==nil || [db length]==0) {
		return @"";
	}
	return [self _pg_urlencode:db];
}

+(NSString* )_pg_urlencode_host:(NSString* )host {
	if(host==nil || [host length]==0) {
		return @"localhost";
	}
	NSCharacterSet* addressChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF.:"];
	NSRange foundNonAddress = [host rangeOfCharacterFromSet:[addressChars invertedSet]];
	if(foundNonAddress.location==NSNotFound) {
		// is likely an address
		return [NSString stringWithFormat:@"[%@]",host];
	} else {
		// is likely a hostname
		return [self _pg_urlencode:host];
	}
}

+(NSString* )_pg_urlencode_port:(NSUInteger)port {
	if(port==0) {
		return @"";
	} else {
		return [NSString stringWithFormat:@":%ld",port];
	}
}

+(id)URLWithLocalDatabase:(NSString* )database params:(NSDictionary* )params {
	return [[NSURL alloc] initWithLocalDatabase:database params:params];
}

+(id)URLWithHost:(NSString* )host database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params {
	return [[NSURL alloc] initWithHost:host database:database ssl:ssl params:params];
}

+(id)URLWithHost:(NSString* )host port:(NSUInteger)port database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params {
	return [[NSURL alloc] initWithHost:host port:port database:database ssl:ssl params:params];
}

-(id)initWithLocalDatabase:(NSString* )database params:(NSDictionary* )params {
	NSString* method = [PGConnection defaultURLScheme];
	NSString* dbenc = [NSURL _pg_urlencode_database:[database stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* queryenc = [NSURL _pg_urlencode_params:params];
	NSParameterAssert(method && dbenc && queryenc);
	return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@:///%@%@",method,dbenc,queryenc]];
}

-(id)initWithHost:(NSString* )host port:(NSUInteger)port database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params {
	NSString* method = [PGConnection defaultURLScheme];
	NSString* sslenc = ssl ? @"s" : @"";
	NSString* dbenc = [NSURL _pg_urlencode_database:[database stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* hostenc = [NSURL _pg_urlencode_host:[host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSString* portenc = [NSURL _pg_urlencode_port:port];
	NSString* queryenc = [NSURL _pg_urlencode_params:params];
	NSParameterAssert(method && dbenc && queryenc && sslenc && hostenc && portenc);
	return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@://%@%@/%@%@",method,sslenc,hostenc,portenc,dbenc,queryenc]];
}

-(id)initWithHost:(NSString* )host database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params {
	return [self initWithHost:host port:0 database:database ssl:ssl params:params];
}

@end
