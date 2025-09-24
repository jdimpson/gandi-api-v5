#!/bin/bash

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
		if test -z "$DOMAIN"; then
			DOMAIN="$1";
		else
			if test -z "$HOST"; then
				HOST="$1";
			else
				if test -z "$CNAME"; then
					CNAME="$1";
				fi
			fi
		fi
	fi
	shift;
done

#VERBOSE=1

if test -z "$GANDI_DYNADNS_PAT"; then
	echo "Please set env variable GANDI_DYNADNS_PAT to the Personal Access Token in your Gandi account that you intend to use for dyanamic DNS" >&2;
	exit 1;
fi

help() {
cat << HERE >&2;
Usage: $0 [ -p PAT ] <domain name> <existing hostname> <new cname>
	-p PAT is optional, and lets you set the GANDI_DYNADNS_PAT environment variable from the command line (not recommended)
	Domain name must be the domain in Gandi where you are setting the dynamic DNS address
	Existing hostname must be the unqualified name that already exists that you want to associate with the new CNAME. 
	New cname is the new CNAME entry that will point back to the Existing hostname.

You must have GANDI_DYNADNS_PAT set as an environment variable, containing the PAT from your Gandi domain hosting account.
You must have curl installed (will someday do wget).
You must have jq installed.

HERE
}

getip() {
	curl -sS "https://ipinfo.io" | jq -r -e .ip;
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

if test -z "$CNAME"; then
	echo "CNAME has not been set" >&2;
	help >&2;
	exit 11;
fi

echo "New CNAME will point to $HOST in domain $DOMAIN" >&2;
RECS=$(getrecords "$GANDI_DYNADNS_PAT" "$DOMAIN" "$RECORD")
if echo "$RECS" | jq -e '.object == "HTTPNotFound"' >/dev/null 2>&1; then
	# invalid domain?
	echo "Could not list records because the resource was not found. Domain $DOMAIN invalid or empty?." >&2;
	help >&2;
	exit 2;
fi

if echo "$RECS" | jq -e '.message | startswith("You must provide an access token")' > /dev/null 2>&1; then
	echo "Could not list records because the Personal Access Token in GANDI_DYNADNS_PAT is invalid" >&2;
	help >&2;
	exit 3;
fi

#echo $RECS | jq .;
REC=$(echo "$RECS" | jq -e '.[] | select(.rrset_name == "'$HOST'")' 2>/dev/null )
if ! test $? -eq 0; then
	if  haserror "$RECS"; then
		echo "Error querying gandi for $HOST, aborting" >&2;
		errorreasons "$RECS" >&2;
		exit 7;
	fi
	echo "No record found for host $HOST, exiting" >&2;
	exit 12;
else
	# TODO: check for existing CNAME and update it if it exists (like dyndns.sh)
	echo "Found record for host $HOST" >&2;
	echo "Creating new CNAME record to point $CNAME to $HOST" >&2;
	OUT=$(createcnamerecord "$GANDI_DYNADNS_PAT" "$DOMAIN" "$HOST" "$CNAME");
	if haserror "$OUT"; then
		echo "Failed to change record $HOST" >&2;
		echo "$OUT" | errorreasons >&2;
		exit 8;
	fi
	echo "$OUT" | jq -r .message >&2;
fi
