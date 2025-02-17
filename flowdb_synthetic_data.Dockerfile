# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
#  FLOWDB
#  -----
#
#
#  Extends the basic FlowDB image to include arbitrary amount of test data.
#
ARG CODE_VERSION=latest
FROM flowminder/flowdb:${CODE_VERSION}

#
#   Install pyenv to avoid being pinned to debian python
#

RUN apt update && apt install git -y --no-install-recommends && \
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove


#
# Install python dependencies
#
COPY --chown=postgres flowdb/testdata/synthetic_data/Pipfile* /docker-entrypoint-initdb.d/sql/syntheticdata/
USER postgres
RUN cd /docker-entrypoint-initdb.d/sql/syntheticdata/ && pipenv install --clear --deploy
USER root
ENV PIPENV_PIPFILE=/docker-entrypoint-initdb.d/sql/syntheticdata/Pipfile
#
#   Add synthetic data to the ingestion directory.
#
RUN mkdir -p /docker-entrypoint-initdb.d/sql/syntheticdata/ && \
    mkdir -p /opt/synthetic_data/ && mkdir -p /docker-entrypoint-initdb.d/py/testdata/

COPY --chown=postgres flowdb/testdata/bin/9900_ingest_synthetic_data.sh /docker-entrypoint-initdb.d/
COPY --chown=postgres flowdb/testdata/bin/9800_population_density.sql.gz /docker-entrypoint-initdb.d/
COPY --chown=postgres flowdb/testdata/bin/9910_run_synthetic_dfs_data_generation_script.sh /docker-entrypoint-initdb.d/
COPY --chown=postgres flowdb/testdata/test_data/py/* /docker-entrypoint-initdb.d/py/testdata/

COPY --chown=postgres flowdb/testdata/bin/generate_synthetic_data*.py /opt/synthetic_data/
ADD --chown=postgres flowdb/testdata/test_data/sql/admin*.sql /docker-entrypoint-initdb.d/sql/syntheticdata/
ADD --chown=postgres flowdb/testdata/synthetic_data/data/NPL_admbnda_adm3_Districts_simplified.geojson /opt/synthetic_data/
# Need to make postgres is owner of any subdirectrories
RUN mkdir docker-entrypoint-initdb.d/sql/syntheticdata/sql &&  chown -R postgres /docker-entrypoint-initdb.d
# Need to relax the permissions in case the container is running as an arbitrary user with a bind mount
RUN chmod -R 777 /docker-entrypoint-initdb.d

