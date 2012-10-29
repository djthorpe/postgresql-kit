//
//  PGServerPreference.h
//  postgresql-kit
//
//  Created by David Thorpe on 29/10/2012.
//
//

#import <Foundation/Foundation.h>

@interface PGServerPreference : NSObject

// properties
@property (retain) NSString* line;

-(id)initWithLine:(NSString* )line;

@end
