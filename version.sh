#!/bin/sh

last_commit_of()
{
	git log -1 --pretty=format:"%h" $1
}

timestamp_of()
{
	git show --no-patch --no-notes --pretty='%ct' $1
}

is_dirty()
{
	local dirty
	dirty=$(git status --short $1 | grep " M ")
	[ $? = 0 ] && echo "-dirty" && return
	dirty=$(git status --short $2 | grep " M ")
	[ $? = 0 ] && echo "-dirty"
}

d1="$1"
d2="$2"
c1=$(last_commit_of $d1)
c2=$(last_commit_of $d2)
t1=$(timestamp_of $c1)
t2=$(timestamp_of $c2)
version=$(git describe --abbrev=0)
commit=
path=

if [ $t1 -gt $t2 ]; then
	commit=$c1
	path=$d1
else
	commit=$c2
	path=$d2
fi

length=$(git log --oneline  $version..$commit | wc -l)
dirty=$(git status --short $path | grep " M ")

echo $length-g$commit$(is_dirty $d1 $d2)
