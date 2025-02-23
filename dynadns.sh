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
				if test -z "$IP"; then
					IP="$1";
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
Usage: $0 [ -p PAT ] <domain name> <dynamic DNS hostname> [dynamic DNS IP address]
	-p PAT is optional, and lets you set the GANDI_DYNADNS_PAT environment variable from the command line (not recommended)
	Domain name must be the domain in Gandi where you are setting the dynamic DNS address
	Dynamic DNS hostname must be the unqualified name you want to associate with the IP address. The resulting fully qualified domain name will be <dynamic DNS hostname>.<domain name>.
	The optional dynamic DNS IP address is the IP address that will be associated with the hostname. If you leave off this argument, then this script will use apinfo.io to try to figure out the desired IP address. That will only work if you are on the Internet, the apinfo.io service is still running and hasn't banned you for some reason, and you are running the script on a network in such a way that ipinfo.io sees the web request as coming from the IP address you want to associate with the hostname. Personally I prefer to remote into my NAT router and grab the IP address directly rather than rely on a third party. But it's easier.

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

if test -z "$IP"; then
	echo "Looking for IP address" >&2;
	IP=$(getip);
fi

lookslike_ipv4() {
	local IP="$1";
	echo "$IP" | grep -q '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*';
}
lookslike_ipv6() {
	local IP="$1";
	echo "$IP" | grep -q '[0-9abcdef][0-9abcdef:\/]*';
}


if lookslike_ipv4 "$IP"; then
	RECORD="A";
else
	if lookslike_ipv6 "$IP"; then
		RECORD="AAAA";
	else
		echo "IP address $IP is not recognized as IPv4 or IPv6 (this may be a bug, sorry)" >&2;
		exit 9;
	fi
fi

echo "IP address for $HOST.$DOMAIN will be set to $IP if needed." >&2;
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
	echo "No record found for host $HOST, need to create, with IP set to $IP" >&2;
	OUT=$(createhostrecord "$GANDI_DYNADNS_PAT" "$DOMAIN" "$HOST" "$IP" "$RECORD");
	if haserror "$OUT"; then
		echo "Error creating $HOST $TYP record, aborting" >&2;
		errorreasons "$OUT" >&2;
		exit 10;
	fi
	echo "$OUT" | jq -r .message >&2;
else
	echo "Found record for host $HOST" >&2;
	CURRIP=$(echo "$REC" | jq -r -e .rrset_values[]);
	if test "$CURRIP" = "$IP"; then
		echo "$HOST.$DOMAIN already has IP $CURRIP, no change needed" >&2;
	else
		echo "$HOST.$DOMAIN has IP $CURRIP, need to change to $IP" >&2;
		OUT=$(updatehostrecord "$GANDI_DYNADNS_PAT" "$DOMAIN" "$HOST" "$IP" "$RECORD");
		if haserror "$OUT"; then
			echo "Failed to change record $HOST" >&2;
			echo "$OUT" | errorreasons >&2;
			exit 8;
		fi
		echo "$OUT" | jq -r .message >&2;
	fi
fi
