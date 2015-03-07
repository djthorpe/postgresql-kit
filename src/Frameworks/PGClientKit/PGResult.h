
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

@interface PGResult : NSObject {
	void* _result;
	PGClientTupleFormat _format;
	NSStringEncoding _encoding;
	NSUInteger _rowNumber;
	NSMutableDictionary* _cachedData;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger affectedRows;
@property (readonly) NSUInteger size;
@property (readwrite) NSUInteger rowNumber;
@property (readonly) BOOL dataReturned;
@property (readonly) NSArray* columnNames;
@property (readonly) PGClientTupleFormat format;

////////////////////////////////////////////////////////////////////////////////
// methods

// fetch rows
-(NSArray* )fetchRowAsArray;
-(NSDictionary* )fetchRowAsDictionary;

@end
