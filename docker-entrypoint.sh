#!/bin/zsh

set -e
# get gid of current user (with ownership of current dir) 
if [ "$MAP_USER_UID" != "no" ]; then
    if [ ! -d "$MAP_USER_UID" ]; then
        MAP_USER_UID=$PWD
    fi

    uid=$(stat -c '%u' "$MAP_USER_UID")
    gid=$(stat -c '%g' "$MAP_USER_UID")

    usermod -u $uid devops 2> /dev/null && {
      groupmod -g $gid devops 2> /dev/null || usermod -a -G $gid devops
    }
fi

# exec /usr/local/bin/gosu devops "$@"
# Use 'su-exec' instead of 'gosu' because it is only 10kb instead of 1.8MB
exec su-exec devops "$@"
