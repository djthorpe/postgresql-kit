
/*
 
 Copyright 2008/2009 David Thorpe, djt@mutablelogic.com
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not 
 use this file except in compliance with the License. You may obtain a copy of 
 the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software 
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 License for the specific language governing permissions and limitations under
 the License.
 
 */

#import <PostgresClientKit/PostgresClientKit.h>

typedef enum {
	FLXPostgresDataObjectSimple  = 0,  	 // simple type requires a primary key	
	FLXPostgresDataObjectSerial  = 1,    // object serial means there is a '_serial' column for the table
	FLXPostgresDataTableSerial   = 2     // table serial means there is a '_serial' table for this object
} FLXPostgresDataObjectType;

@class FLXPostgresDataCache;
@class FLXPostgresDataObject;
@class FLXPostgresDataObjectContext;

#import "FLXPostgresDataCache.h"
#import "FLXPostgresDataObject.h"
#import "FLXPostgresDataObjectContext.h"
#import "FLXPostgresConnection+DataUtils.h"

