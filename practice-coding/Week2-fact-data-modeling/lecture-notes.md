# Week 2

## What can make a pipeline NOT idempotent

- `INSERT INTO` without `TRUNCATE`: Instead start using `MERGE` or `INSERT OVERWRITE` everytime
- Using `Start_date >`  without a corresponding `end_date <`. The pipeline must produce the same result irrespective of WHEN it's ran. Always have a greater than or less than to indicate a time range. This can also cause an `OOME` during backfill. 
- Not using a full set of partition sensors. This can cause the pipeline to run when there is no / partial data. Assume the pipeline is dependent on a function with parameters, and after a query is run it fails to produce all the parameters. This can cause an issue as all the params are not ready and can lead to data discrepancies between production and backfilling. 
- Not using `depends_on_past` for cumulative pipelines. 
- Relying on the "latest" partition of a not properly modeled SCF table.Make sure your cumulative tables are idempotent and are relying on idempotent tables as well. If not, your data will not be reproducible. 


## Should you model as Slowly Changing Dimensions? 

- What is slowly changing dimension: A dimension that is slowly changing overtime. Example, age, country and primary phone. The more slow the data changes, easier it is to model a slowly changing dimension. 
- Some options for data modelling 
  - Latest snapshot: Low idempotency
  - Daily / Monthly / Yearly Snapshot: Slightly easier to backfill as the   data has idempotency for that day.
  - Slowly Changing Dimension: Depending on how slowly the data is dimension, we can use SCD. Essentially, this compresses the data into a single unit. It's a tricky territory but it's there. 
  There are three types for SCD: Type 1, Type 2 and Type 3


## The types of Slowly Changing Dimensions

### Type 0 (Idempotent)

- Aren't actually slowly changing (eg: birth date)
  
### Type 1 (Not Idempotent)

-  You only care about the latest value. This makes your pipeline NOT idempotent. 

### Type 2 (Idempotent: Gold standard)

- You have a date range - start_date to end_date
- Current values usually have either an end_date that is: 
  - NULL
  - Far into the future like 9999-12-31
  - There's usually another column `is_current` of type `Boolean`
- Hard to use since there is more than 1 row per dimension, need to be careful about filtering on time. 

### Type 3 (Not Idempotent)

- You only care about "original" and "current" 
- Pros: You only have 1 row per dimension
- Cons: You lose the history in between original and current
- Is this Idempotent: Partially, which means it's not! 

## How to load SCD2

- Load the entire history in one query. Makes it nimble but inefficient
- Incrementally load the data after the previous SCD is generated
  - Has the same `depends_on_past` constraint
  - Efficient but cumbersome