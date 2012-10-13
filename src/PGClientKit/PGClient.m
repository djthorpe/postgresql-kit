
#include <libpq-fe.h>

NSString* PGClientScheme = @"pgsql";

@implementation PGClient

-(id)init {
	self = [super alloc];
	if(self) {
		m_theConnection = nil;	
	}
	return self;
}

-(void)dealloc {
	// disconnect
}

-(BOOL)connectWithURL:(NSURL* )theURL timeout:(NSUInteger)timeout {
	if(theURL==nil || [[theURL scheme] isEqual:PGClientScheme]==NO) {
		return nil;
	}
	PGClient* theConnection = [[PGClient alloc] init];
	if([theURL user]) {
		[theConnection setUser:[theURL user]];
	}
	if([theURL host]) {
		[theConnection setHost:[theURL host]];
	}
	if([theURL port]) {
		[theConnection setPort:[[theURL port] unsignedIntegerValue]];
	}
	if([theURL path]) {
		NSString* thePath = [[theURL path] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		if([thePath length]) {
			[theConnection setCatalogue:thePath];
		}
	}
	return theConnection;
}


@end
