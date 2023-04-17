#!/bin/bash

set -eux

# Create user, database and permissions
# psql -v ON_ERROR_STOP=1 <<-EOSQL
#  CREATE USER taxi WITH PASSWORD 'ridetlc';
#  CREATE DATABASE tlctriprecords;
#  GRANT ALL PRIVILEGES ON DATABASE tlctriprecords TO taxi;
#  \c tlctriprecords;
#  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO taxi;
#  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO taxi;
# EOSQL

psql -v ON_ERROR_STOP=1 <<-EOSQL
  CREATE DATABASE tlctriprecords;
EOSQL


# Create table
psql -v ON_ERROR_STOP=1 tlctriprecords <<-EOSQL
  CREATE TABLE IF NOT EXISTS triprecords (
    pickup_datetime    TIMESTAMP,
    dropoff_datetime   TIMESTAMP,
    pickup_locationid  INTEGER,\d
    dropoff_locationid INTEGER,
    trip_distance      NUMERIC(7,2)
  );
EOSQL

# Load data
urls="
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-01.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-02.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-03.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-04.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-05.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-06.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-07.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-08.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-09.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-10.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-11.csv.gz
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-12.csv.gz
"

for url in ${urls}
do
  wget "${url}" -O /tmp/yellowtripdata.csv.gz
  # Use the -f flag with gzip command: The -f flag with gzip command forces the file to be overwritten without any prompt. This will force overwrite the existing file with the decompressed file.
  gzip -df /tmp/yellowtripdata.csv.gz
  # Importing all records results in a 6.35GB Docker image
  # Therefore we select every 10th line to decrease size and end up with a 1.21GB Docker image
  time awk -F',' 'NR == 1 || NR % 10 == 0 {print $2","$3","$5","$8","$9}' /tmp/yellowtripdata.csv > /tmp/yellowtripdata_small.csv
  time psql -v ON_ERROR_STOP=1 tlctriprecords <<-EOSQL
    COPY triprecords(pickup_datetime,dropoff_datetime,trip_distance,pickup_locationid,dropoff_locationid)
    FROM '/tmp/yellowtripdata_small.csv' DELIMITER ',' CSV HEADER;
EOSQL
done

psql -v ON_ERROR_STOP=1 <<-EOSQL
  CREATE USER taxi WITH PASSWORD 'ridetlc';
  GRANT ALL PRIVILEGES ON DATABASE tlctriprecords TO taxi;
  \c tlctriprecords;
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO taxi;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO taxi;
EOSQL


pg_ctl stop
