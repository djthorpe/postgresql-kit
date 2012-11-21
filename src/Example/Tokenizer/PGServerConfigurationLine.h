
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"

////////////////////////////////////////////////////////////////////////////////

typedef enum {
	PGTypeSQString = 1,
	PGTypeDQString,
	PGTypeKeyword,
	PGTypeOctal,
	PGTypeDecimal,
	PGTypeFloat,
	PGTypeBool
} PGServerConfigurationValueType;

////////////////////////////////////////////////////////////////////////////////

@interface PGServerConfigurationValue : NSObject {
	PGServerConfigurationValueType _type;
	NSString* _value;
	BOOL _bool;
	NSString* _suffix;
}

// constructors
+(PGServerConfigurationValue* )valueWithSQString:(const char* )value;
+(PGServerConfigurationValue* )valueWithDQString:(const char* )value;
+(PGServerConfigurationValue* )valueWithKeyword:(const char* )value;
+(PGServerConfigurationValue* )valueWithOctal:(const char* )value;
+(PGServerConfigurationValue* )valueWithDecimal:(const char* )value;
+(PGServerConfigurationValue* )valueWithFloat:(const char* )value;
+(PGServerConfigurationValue* )valueWithBool:(const char* )value;

// properties
@property NSString* suffix;
@property (readonly) NSString* quotedValue;
@property NSObject* object;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerConfigurationLine : PGTokenizerLine {
	NSUInteger _state;
	BOOL _enabled;
	NSString* _key;
	PGServerConfigurationValue* _value;
	NSMutableString* _comment;
	NSMutableString* _line;
}

// properties
@property BOOL enabled;
@property (readonly) NSString* key;
@property PGServerConfigurationValue* value;
@property (readonly) NSString* comment;
@property (readonly) NSString* line;

@end
