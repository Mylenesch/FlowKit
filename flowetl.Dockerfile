# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
#  FLOWETL
#  -----

FROM apache/airflow:2.7.3-python3.8@sha256:83253f28743cdd69ae1b731ed11901b5327156512d525b2ad301d28b327d68aa

ENV AIRFLOW__CORE__DAGS_FOLDER ${AIRFLOW_HOME}/dags
ENV AIRFLOW__CORE__LOAD_EXAMPLES False
# Turn off api access
ENV AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.session
ENV AIRFLOW__WEBSERVER__RBAC=True

# Needed for custom users passed through docker's --user argument, otherwise it's /
ENV HOME ${AIRFLOW_USER_HOME_DIR}

# Install FlowETL module

ARG SOURCE_VERSION=0+unknown
ENV SOURCE_VERSION=${SOURCE_VERSION}
ENV SOURCE_TREE=FlowKit-${SOURCE_VERSION}
WORKDIR /${SOURCE_TREE}/flowetl

COPY --chown=airflow . /${SOURCE_TREE}/


USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev build-essential &&  \
    sudo -u airflow -s pip install --no-deps --no-cache-dir --ignore-installed -r requirements.txt && \
    apt-get -y remove build-essential && \
    apt purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/*
USER airflow
RUN cd flowetl && pip install --no-deps --no-cache-dir --user .


WORKDIR ${AIRFLOW_HOME}
COPY ./flowetl/entrypoint.sh /flowetl_entry.sh
COPY ./flowetl/init.sh /init.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/flowetl_entry.sh"]
# set default arg for entrypoint
EXPOSE 80
EXPOSE 8080
ENV FLOWETL_PORT=8080

CMD ["webserver"]


