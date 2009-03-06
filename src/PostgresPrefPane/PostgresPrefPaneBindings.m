//
//  PostgresPrefPaneBindings.m
//  postgresql
//
//  Created by David Thorpe on 27/02/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PostgresPrefPaneBindings.h"

@implementation PostgresPrefPaneBindings

@synthesize bindServerVersion;
@synthesize bindServerStatus;
@synthesize bindDiskUsage;
@synthesize bindProcessorUsage;
@synthesize bindServerStatusImage;
@synthesize bindServerPort;
@synthesize bindServerPortMinValue;
@synthesize bindServerPortMaxValue;
@synthesize bindServerPortEnabled;
@synthesize bindIsRemoteAccess;
@synthesize bindIsRemoteAccessEnabled;
@synthesize bindPortMatrixIndex;
@synthesize bindPortMatrixEnabled;
@synthesize bindTabViewIndex;
@synthesize bindIsBackupEnabled;

////////////////////////////////////////////////////////////////////////////////
// destructor

-(void)dealloc {
	// release objects
	[self setBindServerVersion:nil];
	[self setBindServerStatus:nil];
	[self setBindDiskUsage:nil];
	[self setBindProcessorUsage:nil];
	[self setBindServerStatusImage:nil];
	[super dealloc];
}
@end
