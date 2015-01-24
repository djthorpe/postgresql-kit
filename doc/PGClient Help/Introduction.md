

# How to use PGClient

This framework is used to start, stop and restart a PostgresSQL server programatically, as a background process to the main executing process. The case for doing this is fairly limited, since you would ideally run your database server separately from any user-process. However, you may wish to 
have a feature-rich data storage engine in your application (you could also use CoreData or SQLite, of course). You should check out [PGServer](pgserver.md) or 
[PGFoundationServer](pgfoundationserver.md) example source code to see how you can use this framework in your own applications.

 * [Adding and Removing Databases](Databases.md)
 * [Running Queries](Queries.md)
