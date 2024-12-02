#!/bin/sh

# this script uses the liveDNS API, not the Domain API, at least currently
# https://api.gandi.net/docs/livedns/

. ./gandi_v5_funcs.sh

VERBOSE=1

if test -z "$GANDI_DYNADNS_PAT"; then
	echo "Please set env variable GANDI_DYNADNS_PAT to the Personal Access Token in your Gandi account that you intend to use for dyanamic DNS" >&2;
	exit 1;
fi

help() {
	echo "Usage: $0 <domain name> <dynamic DNS hostname> [dynamic DNS IP address]" >&2;
	echo "	Domain name must be the domain in Gandi where you are setting the dynamic DNS address"
	echo "	Dynamic DNS hostname must be the unqualified name you want to associate with the IP address. The resulting fully qualified domain name will be <dynamic DNS hostname>.<domain name>."
	echo "	The optional dynamic DNS IP address is the IP address that will be associated with the hostname. If you leave off this argument, then this script will use apinfo.io to try to figure out the desired IP address. That will only work if you are on the Internet, the apinfo.io service is still running and hasn't banned you for some reason, and you are running the script on a network in such a way that ipinfo.io sees the web request as coming from the IP address you want to associate with the hostname. Personally I prefer to remote into my NAT router and grab the IP address directly rather than rely on a third party. But it's easier."
	echo
	echo "You must have GANDI_DYNADNS_PAT set as an environment variable, containing the PAT from your Gandi domain hosting account."
	echo "You must have curl installed (will someday do wget)."
	echo "You must have jq installed."
	echo
}

getrecords "$GANDI_DYNADYNS_PAT" "$MYDOMAIN" "A"
