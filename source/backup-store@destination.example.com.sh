#!/bin/sh
###########################################################
##
## push backups to remote storage.
##
## Requires no special permissions on destination host.
##
###########################################################

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
