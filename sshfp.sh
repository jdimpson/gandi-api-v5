#!/bin/sh

THISDIR="$(dirname "$(readlink -f "$0")")"
GANDI_FUNCS="gandi_v5_funcs.sh"
if test -r "$THISDIR/$GANDI_FUNCS"; then
	. "$THISDIR/$GANDI_FUNCS"
else
	echo "Cannot find $GANDI_FUNCS; it should be in the same folder as this script ($THIDIR)" >&2;
	exit 6;
fi

# someday I'll just learn to accept getopts
while test $# -gt 0; do
	if test "$1" = "-p"; then
		export GANDI_DYNADNS_PAT="$2";
		shift;
	else
		if test -z "$HOST"; then
			HOST="$1";
		else
			if test -z "$DOMAIN"; then
				DOMAIN="$1";
			else
				if test -z "$FILE"; then
					FILE="$1";
				fi
			fi
		fi
	fi
	shift;
done

VERBOSE=1

if test -z "$GANDI_DYNADNS_PAT"; then
	echo "Please set env variable GANDI_DYNADNS_PAT to the Personal Access Token in your Gandi account that you intend to use for dyanamic DNS" >&2;
	exit 1;
fi

help() {
cat << HERE >&2;
Usage: $0 [ -p PAT ] <ssh server name> <domain name> [ssh server key file]
	-p PAT is optional, and lets you set the GANDI_DYNADNS_PAT environment variable from the command line (not recommended)
	ssh server name is the unqualified host name of the SSH server for which you want to create SSHFP records. This lets you use VerifyHostKeyDNS option in your SSH client program.  ssh server name must already have host name domain record in Gandi 
	domain name is the DNS domain name you have at Gandi, and for which your PAT is valid.
	ssh server key file is an optional file containing the desired SSH key to be added to the SSHFP record. If it is ommitted, the host will be directly contacted to get all of it's host keys, and a record will be made for each one.

You must have GANDI_DYNADNS_PAT set as an environment variable, containing the PAT from your Gandi domain hosting account.
You must ssh-keygen installed.
You must have curl installed (will someday do wget).
You must have jq installed.

HERE
	return 0;
}

getkeyfile() {
	return 0;
}

if test -z "$DOMAIN"; then
	echo "DOMAIN has not been set" >&2;
	help >&2;
	exit 4;
fi

if test -z "$HOST"; then
	echo "HOST has not been set" >&2;
	help >&2;
	exit 5;
fi

FQDN="$HOST.$DOMAIN";

if test -z "$FILE"; then
	echo "No key file provided, will query them directly from $FQDN" >&2;
	FILE=$(getkeyfile "$FQDN");
fi

F=
if ! test -z "$FILE"; then
	F="-f $FILE";
fi

# this is a bad hack. Need to work out way to naturally provide json strings to the gandi-api-v5 functions
VALS=$(ssh-keygen -r "$FQDN" $F | while read h in sshfp one two hash; do
	echo -n "$one $two $hash"'","';
done; echo;);
VALS=$(echo "$VALS" | sed -e 's/","$//');

OUT=$(createhostrecord "$GANDI_DYNADNS_PAT" "$DOMAIN" "$HOST" "$VALS" "SSHFP");

if hashttpcode "$OUT"; then
	code=$(gethttpcode "$OUT");
	if test "$code" -eq 200 || test "$code" -eq 204; then
		true;
		# so far, "good" responses don't populate the "code" field to the object
	else
		if test "$code" -eq 404; then
			echo "Could not list records because the resource was not found. Domain $DOMAIN invalid or empty?." >&2;
			echo >&2;
			help >&2;
		else
			if test "$code" -eq 403; then
				echo "Could not create records because the Personal Access Token in GANDI_DYNADNS_PAT is invalid" >&2;
				echo >&2;
				help >&2;
			else
				echo "Unknown HTTP code: $code ($OUT)" >&2;
			fi
		fi
		exit 2;
	fi
fi

RES=$(echo "$OUT" | jq -r .message);

echo "$RES" >&2;
if test "$RES" -eq "DNS Record Created"; then
	exit 0;
else
	exit 3;
fi
