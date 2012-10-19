//
//  Application.h
//  postgresql-kit
//
//  Created by David Thorpe on 17/10/2012.
//
//

#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

@interface Application : NSObject <PGConnectionDelegate>

@property int signal;
@property PGConnection* db;

-(int)run;

@end
