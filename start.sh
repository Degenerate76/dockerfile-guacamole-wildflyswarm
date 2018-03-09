#!/bin/sh -e
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

##
## @fn start.sh
##
## Heavily simplified from official guacamole docker image.
##
## Automatically configures and starts Guacamole under Tomcat. Guacamole's
## guacamole.properties file will be automatically generated based on the
## environment variables that are set.The Tomcat process will ultimately
## replace the process of this script, running in the foreground until
## terminated.
##

##
## Sets the given property to the given value within guacamole.properties,
## creating guacamole.properties first if necessary.
##
## @param NAME
##     The name of the property to set.
##
## @param VALUE
##     The value to set the property to.
##
set_property() {

    NAME="$1"
    VALUE="$2"

    # Ensure guacamole.properties exists
    if [ ! -e "$GUACAMOLE_PROPERTIES" ]; then
        echo "# guacamole.properties - generated `date`" > "$GUACAMOLE_PROPERTIES"
    fi

    # Set property
    echo "$NAME: $VALUE" >> "$GUACAMOLE_PROPERTIES"

}

##
## Sets the given property to the given value within guacamole.properties only
## if a value is provided, creating guacamole.properties first if necessary.
##
## @param NAME
##     The name of the property to set.
##
## @param VALUE
##     The value to set the property to, if any. If omitted or empty, the
##     property will not be set.
##
set_optional_property() {

    NAME="$1"
    VALUE="$2"

    # Set the property only if a value is provided
    if [ -n "$VALUE" ]; then
        set_property "$NAME" "$VALUE"
    fi

}


GUACAMOLE_PROPERTIES="$GUACAMOLE_HOME/guacamole.properties"

# Start with a fresh GUACAMOLE_PROPERTIES
rm -f "$GUACAMOLE_PROPERTIES"

# Use default guacd and Postgres ports if none specified
GUACD_PORT="${GUACD_PORT-4822}"
POSTGRES_PORT="${POSTGRES_PORT-5432}"

# Verify required parameters are present
if [ -z "$GUACD_HOSTNAME" -o -z "$POSTGRES_HOSTNAME" -o -z "$POSTGRES_USER" -o -z "$POSTGRES_PASSWORD" -o -z \
    "$POSTGRES_DATABASE" ]; then
    cat <<END
FATAL: Missing required environment variables
-------------------------------------------------------------------------------
You must provide each of the following environment variables:

    GUACD_HOSTNAME     The hostname or IP address of guacd.

    POSTGRES_HOSTNAME  The hostname or IP address of the PostgreSQL server.

    POSTGRES_USER      The user to authenticate as when connecting to
                       PostgreSQL.

    POSTGRES_PASSWORD  The password to use when authenticating with PostgreSQL
                       as POSTGRES_USER.

    POSTGRES_DATABASE  The name of the PostgreSQL database to use for Guacamole
                       authentication.
END
    exit 1;
fi

##
## Adds properties to guacamole.properties which configure the guacd
## connection, select the PostgreSQL authentication provider, and
## configure it to connect to specified PostgreSQL server.
##
set_property "guacd-hostname"      "$GUACD_HOSTNAME"
set_property "guacd-port"          "$GUACD_PORT"
set_property "postgresql-hostname" "$POSTGRES_HOSTNAME"
set_property "postgresql-port"     "$POSTGRES_PORT"
set_property "postgresql-database" "$POSTGRES_DATABASE"
set_property "postgresql-username" "$POSTGRES_USER"
set_property "postgresql-password" "$POSTGRES_PASSWORD"

set_optional_property "postgresql-absolute-max-connections"               "$POSTGRES_ABSOLUTE_MAX_CONNECTIONS"
set_optional_property "postgresql-default-max-connections"                "$POSTGRES_DEFAULT_MAX_CONNECTIONS"
set_optional_property "postgresql-default-max-group-connections"          "$POSTGRES_DEFAULT_MAX_GROUP_CONNECTIONS"
set_optional_property "postgresql-default-max-connections-per-user"       "$POSTGRES_DEFAULT_MAX_CONNECTIONS_PER_USER"
set_optional_property "postgresql-default-max-group-connections-per-user" "$POSTGRES_DEFAULT_MAX_GROUP_CONNECTIONS_PER_USER"

##
## Finish by starting Guacamole under Wildfly, replacing
## the current process with the Wildfly process.
##
exec /wildfly-servlet/bin/standalone.sh -b 0.0.0.0
