
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

@interface NSString (PGNetworkValidationAdditions)

/**
 *  Determine if the string is a valid hostname
 *
 *  @return returns YES if the string is a valid hostname
 */
-(BOOL)isNetworkHostname;

/**
 *  Determine if the string is a valid IP address (either IPv4 or IPv6)
 *
 *  @return returns YES if the string is a valid IP address
 */
-(BOOL)isNetworkAddress;

/**
 *  Determine if the string is a valid IPv4 address
 *
 *  @return returns YES if the string is a valid IPv4 address
 */
-(BOOL)isNetworkAddressV4;

/**
 *  Determine if the string is a valid IPv6 address
 *
 *  @return returns YES if the string is a valid IPv6 address
 */
-(BOOL)isNetworkAddressV6;

@end
