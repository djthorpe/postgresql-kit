//
//  PostgresPrefPaneBindings.m
//  postgresql
//
//  Created by David Thorpe on 27/02/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PostgresPrefPaneBindings.h"

NSTimeInterval PostgresBackupTimeInterval_Hourly = (NSTimeInterval)(60.0 * 60.0);
NSTimeInterval PostgresBackupTimeInterval_TwiceDaily = (NSTimeInterval)(60.0 * 60.0 * 12.0);
NSTimeInterval PostgresBackupTimeInterval_Daily = (NSTimeInterval)(60.0 * 60.0 * 24.0);
NSTimeInterval PostgresBackupTimeInterval_TwiceWeekly = (NSTimeInterval)(60.0 * 60.0 * 24.0 * 3.5);
NSTimeInterval PostgresBackupTimeInterval_Weekly = (NSTimeInterval)(60.0 * 60.0 * 24.0 * 7.0);
NSTimeInterval PostgresBackupTimeInterval_Fortnightly = (NSTimeInterval)(60.0 * 60.0 * 24.0 * 14.0);
NSTimeInterval PostgresBackupTimeInterval_30sec = 30.0;

@implementation PostgresPrefPaneBindings

@synthesize bindServerVersion;
@synthesize bindServerStatus;
@synthesize bindDiskUsage;
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
@synthesize bindBackupIntervalTag;
@synthesize bindBackupIntervalEnabled;
@synthesize bindBackupFreeSpaceTag;
@synthesize bindBackupFreeSpaceEnabled;
@synthesize bindStartButtonEnabled;
@synthesize bindStopButtonEnabled;
@synthesize bindInstallButtonEnabled;
@synthesize bindUninstallButtonEnabled;
@synthesize bindNewPassword;
@synthesize bindNewPassword2;
@synthesize bindExistingPassword;
@synthesize bindPasswordButtonEnabled;
@synthesize bindPasswordMessage;

////////////////////////////////////////////////////////////////////////////////
// destructor

-(void)dealloc {
	// release objects
	[self setBindServerVersion:nil];
	[self setBindServerStatus:nil];
	[self setBindDiskUsage:nil];
	[self setBindServerStatusImage:nil];
	[self setBindNewPassword:nil];
	[self setBindNewPassword2:nil];
	[self setBindExistingPassword:nil];
	[self setBindPasswordMessage:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)setBackupIntervalTagFromInterval:(NSTimeInterval)theInterval {
	if(theInterval <=PostgresBackupTimeInterval_30sec) {
		[self setBindBackupIntervalTag:99];
	} else if(theInterval <= PostgresBackupTimeInterval_Hourly) {
		[self setBindBackupIntervalTag:0];
	} else if(theInterval <= PostgresBackupTimeInterval_TwiceDaily) {
		[self setBindBackupIntervalTag:1];
	} else if(theInterval <= PostgresBackupTimeInterval_Daily) {
		[self setBindBackupIntervalTag:2];
	} else if(theInterval <= PostgresBackupTimeInterval_TwiceWeekly) {
		[self setBindBackupIntervalTag:3];
	} else if(theInterval <= PostgresBackupTimeInterval_Weekly) {
		[self setBindBackupIntervalTag:4];		
	} else {
		[self setBindBackupIntervalTag:5];		
	}
}

-(NSTimeInterval)backupTimeIntervalFromTag {
	if([self bindBackupIntervalTag]==0) { // hourly
		return PostgresBackupTimeInterval_Hourly;
	}
	if([self bindBackupIntervalTag]==1) { // twice daily
		return PostgresBackupTimeInterval_TwiceDaily;
	}
	if([self bindBackupIntervalTag]==2) { // daily
		return PostgresBackupTimeInterval_Daily;
	}
	if([self bindBackupIntervalTag]==3) { // twice weekly
		return PostgresBackupTimeInterval_TwiceWeekly;
	}
	if([self bindBackupIntervalTag]==4) { // weekly
		return PostgresBackupTimeInterval_Weekly;
	}
	if([self bindBackupIntervalTag]==5) { // fortnighly
		return PostgresBackupTimeInterval_Fortnightly;
	}
	if([self bindBackupIntervalTag]==99) { // every 30 secs
		return PostgresBackupTimeInterval_30sec;
	}
	return 0.0;	
}

-(void)setBackupFreeSpaceTagFromPercent:(NSInteger)thePercent {
	[self setBindBackupFreeSpaceTag:thePercent];
}

-(NSInteger)backupFreeSpacePercentFromTag {
	return [self bindBackupFreeSpaceTag];
}

-(NSString* )existingPassword {
	NSString* existingPassword1 = [[self bindExistingPassword] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(existingPassword1==nil) {
		return @"";
	} else {
		return existingPassword1;
	}
}

-(NSString* )newPassword {
	NSString* newPassword1 = [[self bindNewPassword] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString* newPassword2 = [[self bindNewPassword2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	
	if(newPassword1==nil && newPassword2==nil) {
		return @"";
	} else if([newPassword1 isEqual:newPassword2]) {
		return newPassword1;
	} else {
		return nil;
	}
}

@end
