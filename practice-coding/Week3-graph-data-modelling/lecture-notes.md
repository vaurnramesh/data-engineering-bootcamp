# Week 3

## Graph data modelling

- It is more relationship focused than entity focused
- Schema's are flexible
- Additive vs non-additive dimensions
- The power of Enums
- Today's focus is to build a data layer of a graph agnostic data model

## What makes the data additive?

- Age is additive
  - For example, Australia population = 1 year olds + 2 year olds + ..... 115 year olds = 25 million
- Counting drivers by cars is NOT additive
  - The number of Honda drivers != # of Civic drivers + # of Corolla driver + # of Accord drivers …
  - Because one person can own two honda cars. But the number of Honda cars CAN be additive!
- The number of active users != # of users on web + # of users on Android + # of users on EZachly iPhone

## The essential nature of additivity

- A dimension is additive over a specific window of time, if and only if, the grain of data over that window can only ever be one value at a time!

## How does additivity help? 

- You don’t need to use `COUNT(DISTINCT)` on preaggregated dimensions
- Non-additive dimensions are usually only non-additive with respect to COUNT aggregations but not SUM aggregations. Basically can use SUM but not generally COUNT. 

## When to use enums? 

- Enums are great for low-to-medium cardinality
- Example: Country is a great example of where `Enums` start to struggle. Because less than 50 enums are a good rule of thumb. 

## Why should you use enums? 

- Built in data quality
- Built in static fields: Some static fields are pretty evident if you have enums
- Built in documentation: If you have a list, enum gives you all the possible items in the list. 

## What type of use cases is this enum pattern useful?

Whenever you have tons of sources mapping to a shared schema

-  Airbnb: Unit Economics (fees, coupons, credits, insurance, infrastructure cost, taxes, etc)
-  Netflix: Infrastructure Graph (applications, databases, servers, code bases, CI/CD jobs, etc)
-  Facebook: Family of Apps (oculus, instagram, facebook, messenger, whatsapp, threads, etc)
-  

## How do you model data from disparate sources into a shared schema?

How do you model when you have like 40 tables and then pull into one table where most of the values are null at one time. This is when you need a flexible schema

In flexible schema uses a map data type which is also called the graph data type. 

## Flexible Schema

- As you get more columns, just throw them in the MAP. The Map can get bigger and bigger. In spark there is a fundamental limit to about 65K. 
- Manage a lot more columns
- You do not have a lot of NULL columns. Such columns are not even in the MAP. 
- “Other_properties” column is pretty awesome for rarely-used-but-needed columns
- Downsides: Compression (JSON, Map) and readability, query-ability.

## How is graph data modeling different?

Graph modeling is RELATIONSHIP focused, not ENTITY focused. 

- Super secret sauce for graph data modelling: They usually have the same exact schema. Since it's not entity based, we do not need a many columns. This how the model usually looks like - 
  - Identifier: STRING
  - Type: STRING
  - Properties: MAP<STRING, STRING>

- A little more depth: 
  - subject_identifier: STRING
  - Subject_type: VERTEX_TYPE
  - Object_identifier: STRING
  - Object_type: VERTEX_TYPE
  - Edge_type: EDGE_TYPE
  - Properties: MAP<STRING, STRING>

## Graph diagram

Chicago Bulls ----> (playes on) ----> Michael Jordan 
                                        |
                                        |
                                        |
                                    Plays against
                                        |
                                        |
                                        |
Utah Jazz <---- Playes on <----  John Stockton    