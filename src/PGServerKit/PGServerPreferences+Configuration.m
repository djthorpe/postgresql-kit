#import "PGServerPreferences+Configuration.h"

@implementation PGServerPreferences (Configuration)

-(NSString* )quoted:(NSString* )value {
	NSString* value2 = [value stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	NSString* value3 = [value2 stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	return [NSString stringWithFormat:@"'%@'",value3];
}

-(NSUInteger)port {
	NSParameterAssert([self type]==PGServerPreferencesTypeConfiguration);
	NSString* value = [self valueForKey:@"port"];
	if(value==nil) {
		return 0;
	}
	if([value length]==0) {
		return PGServerDefaultPort;
	}
	NSDecimalNumber* port = [NSDecimalNumber decimalNumberWithString:value];	
	if(port==nil) {
		return 0;
	}
	return [port unsignedIntegerValue];
}

-(void)setPort:(NSUInteger)value {
	NSParameterAssert([self type]==PGServerPreferencesTypeConfiguration);
	NSParameterAssert(value > 0);
	[self setValue:[NSString stringWithFormat:@"%lu",value] forKey:@"port"];
	if(value==PGServerDefaultPort) {
		[self setEnabled:NO forKey:@"port"];
	} else {
		[self setEnabled:YES forKey:@"port"];
	}
}

-(NSString* )listenAddresses {
	NSParameterAssert([self type]==PGServerPreferencesTypeConfiguration);
	return [self valueForKey:@"listen_addresses"];
}

-(void)setListenAddresses:(NSString* )value {
	NSParameterAssert([self type]==PGServerPreferencesTypeConfiguration);
	NSString* value2 = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([value2 length]==0 || [value2 isEqualToString:@"'localhost'"]) {
		[self setValue:@"localhost" forKey:@"listen_addresses"];
		[self setEnabled:NO forKey:@"listen_addresses"];
	} else {
		[self setValue:[self quoted:value2] forKey:@"listen_addresses"];
		[self setEnabled:YES forKey:@"listen_addresses"];
	}
}


@end
