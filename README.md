
This set of frameworks and test applications provides a kit of frameworks and 
tools for deploying the PostgreSQL database on the Mac OS X operating system. 
For more information on PostgreSQL see: http://www.postgresql.org/.

The code provided will compile to the following products:

  * [PGServerKit] provides an emdedded PostgreSQL database which runs locally 
    in user-space. You can start and stop the database programatically, edit 
	access control, configuration and perform data backups of the database. 
	This database could be used if you want to provide a persistent data store 
	in your application which is "beefier" than using SQLite, for example.

  * [PGClientKit] provides an embedded client library, which is simply an 
    interface to the normal postgres "libpq" library, for Mac and iOS. It
	translates many PostgreSQL types to and from native Foundation types 
	(NSString, NSNumber, etc) and a way to extend to support more types.

  * [PGServer] is a user-space server application which allows you to configure,
    run, administer and monitor a PostgresSQL server. It's purely an example of
	using PGServerKit and PGClientKit, since running a postgresql server in 
	user-space isn't necessarily the best approach.

  * [PGClient] is a user-space client application which allows you to 
	administer and use a remote PostgreSQL server. Again, it's an example of 
	using PGClientKit to connect to remote databases.

==Screenshots!==

TBD

==Compiling==

There are several targets in the XCode project. You'll need to build the 
"Build Everything Useful!" target to compile everything at once. You will 
end up with two frameworks and the applications in the Products directory.
During compilation, postgresql-9.1.5.tar is uncompressed and compiled. If 
you don't do this step first the other targets will not build. The tar file 
is uncompressed to ${DERIVED_SOURCES_DIR}. The build is performed and the 
results of the build are placed in ${BUILT_PRODUCTS_DIR}. A link to the 
current binaries is made from "postgres-current".

The built frameworks should be workable on Intel based machines, for 
Lion 10.7 64-bit and above.


==Limitations==

This software is in development and as such there are plenty of limitations
and probably issues. These are listed on each component page. If you know of
any issues or feature requests, please let me know and I may be able to help out.

License
=======

Copyright 2009-2012 David Thorpe

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
   
