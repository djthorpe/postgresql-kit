
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

typedef enum {
	PGServerPreferencesTypeConfiguration,
	PGServerPreferencesTypeAuthentication
} PGServerPreferencesType;

@interface PGServerPreferences : NSObject

@property (assign) BOOL modified;
@property (assign) PGServerPreferencesType type;

-(id)initWithConfigurationFile:(NSString* )path;
-(id)initWithAuthenticationFile:(NSString* )path;

@end
