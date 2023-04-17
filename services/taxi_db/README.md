# Taxi DB

The Dockerfile in this directory builds a Postgres DB with NYC Yellow Taxi data from 2019. Due to the size of
the dataset, the Docker image becomes very large, so we select on every Xth line from the input data to have a
Docker image of approximately 1GB.

# Login
psql -U postgres tlctriprecords

# tip
https://stackoverflow.com/questions/35594987/how-to-force-docker-for-a-clean-build-of-an-image

use `docker build --no-cache`