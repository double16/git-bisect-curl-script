#!/bin/bash -x

#
# Script intended to be used with 'git bisect' to find issues in the git-bisect-curl-app application. This script does not
# perform the actual application test. For clarity it handles starting and stopping the application only. See 'test.sh' for
# testing the application.
#
# Per git bisect man page: exit status 0 for 'good', 1-124 for 'bad', 125 to 'skip', 126-127 are reserved and will cause bisect to stop.
#

# Get the working directory, it should be the root of the application checkout
WD="$(dirname $0)"

# If there were any patches to enable debugging or install a test harness, put them here

# Start the app
./grailsw -Dserver.port=8090 -Ddisable.auto.recompile=true -non-interactive RunApp &
GRAILS_PID=$!
sleep 15s

# Run the test, includes waiting for the application to start
"${WD}/test.sh"
status=$?

# Stop the app
kill $!
sleep 5s

# undo the patching to allow clean flipping to the next commit
git reset --hard

# return control
exit $status

