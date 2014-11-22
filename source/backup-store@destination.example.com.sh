#!/bin/sh
###########################################################
##
## push backups to remote storage.
##
## Requires no special permissions on destination host.
##
###########################################################
# Copyright (c) 2014, Marcus Rohrmoser mobile Software
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
# 
# 2. The software must not be used for military or intelligence or related purposes nor
#    anything that's in conflict with human rights as declared in http://www.un.org/en/documents/udhr/ .
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# reverse: http://blog.interlinked.org/tutorials/rsync_time_machine.html

src="/"

dst_host="$(basename "$0" .sh)"
dst_dir="~/$(/bin/hostname)"
# dst_dir="~/..." # manually set a pretty hostname if desired

ssh_opts="-i /root/.ssh/$dst_host"


###########################################################

excl="$(dirname "$0")/$(basename "$0" .sh).exclude"
timestamp=$(/bin/date "+%Y-%m-%d-%H%M%S")

/bin/date

# debian: save package list
apt-mark showmanual > "$HOME/apt-mark.showmanual"
# ufw firewall: save status
/usr/sbin/ufw status verbose > "$HOME/ufw.status"

/usr/bin/rsync -e "ssh $ssh_opts" -azP --bwlimit 500 --acls --hard-links --sparse --xattrs --compress-level=9 \
  --exclude-from="$excl" \
  --link-dest=../Latest "$src" "$dst_host:$dst_dir/$timestamp.incomplete"
# |tee $HOME/Downloads/backup.stdout 2> $HOME/Downloads/backup.stderr 
/bin/echo rsync exit code: $?

/usr/bin/ssh $ssh_opts $dst_host sh backup-finish.sh "$dst_dir/$timestamp.incomplete"

/bin/echo ssh exit code: $?

/bin/date
