#!/bin/bash -x

#
# Test the application using the web interface with 'curl'. Assume the application has been built and started.
#

# We're going to keep a log of HTML output for validating the test
mkdir -p "$(dirname $0)/log"
LOG="$(dirname $0)/log/test.log"
rm ${LOG}

# The cookie jar is used to maintain the session across curl invocations. We'll tell curl to read from here for requests, write to here for responses.
COOKIE_JAR="$(dirname $0)/log/cookies.txt"
rm -f "${COOKIE_JAR}"

# This is the root of the application we're testing
APP="http://localhost:8090/git-bisect-curl-app/"

# Common curl options:
# --silent	this is an automated script
# --insecure	ignore SSL certs for local testing
# --cookie	use the cookies found in the cookie jar, allows sessions across invocations
# --cookie-jar	store new cookies in the cookie jar, allows sessions across invocations
# --fail	curl should return a failure exit status if the HTTP request fails
# --location	follow HTTP redirects via the Location header
CURL_OPTS="--silent --insecure --cookie "${COOKIE_JAR}" --cookie-jar "${COOKIE_JAR}" --fail --location"

# Ensure the application is running by using the --fail option when an HTTP status code of 400+ is returned
# We wait a maximum of 90 seconds with 15 seconds between checks
START=$(date +%s)
while [ $((($(date +%s)-${START}))) -lt 90 ] && ! curl --silent --cookie-jar "${COOKIE_JAR}" --fail "${APP}">>"${LOG}"; do
	sleep 15s;
done
[ $? -ne 0 ] && exit 125

# Create a new record. Grails in development mode starts with an empty database, so that makes it easier because we don't need to worry about unique constraints, etc.
# --data @-	POST name-value pairs to the URL using a shell "here" document
# Exit 125 (skip commit) on error here because it means creating a new record doesn't work, which isn't what we're looking for
curl ${CURL_OPTS} --data @- "${APP}person/save">>"${LOG}" <<EOF || exit 125
firstName=John&lastName=Doe&phone=8005551212&favoriteColor=&birthCountry=&birthCity=&email=&birthYear=0&create=Create
EOF

# Show the edit record form
# Exit 125 (skip commit) on error here because it means showing the edit form doesn't work, which isn't what we're looking for
curl ${CURL_OPTS} "${APP}person/edit/1">>"${LOG}" || exit 125

# We know the issue is the update action is incorrect, so look in the log for the correct action
grep 'input.*name="_action_update"' "${LOG}" || exit 1

# This is a good commit
exit 0

