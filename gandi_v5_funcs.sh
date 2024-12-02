#!/bin/sh

# this script uses the liveDNS API, not the Domain API, at least currently
# https://api.gandi.net/docs/livedns/

getrecords() {
	local PAT="$1";
	local DOM="$2";
	local TYP="$3";

	if test -z "$TYP"; then
		URL="https://api.gandi.net/v5/livedns/domains/$DOM/records"
	else
		URL="https://api.gandi.net/v5/livedns/domains/$DOM/records?rrset_type=$TYP"
	fi

	curl -sS \
	  "$URL" \
	  -H "Authorization: Bearer $GANDI_DYNADNS_PAT" \
	  -H "Content-type: application/json" 
	echo;
}

gethostrecord() {
	local PAT="$1";
	local DOM="$2";
	local NAM="$3";
	URL="https://api.gandi.net/v5/livedns/domains/$DOM/records/$NAM"
	curl -sS \
	  "$URL" \
	  -H "Authorization: Bearer $GANDI_DYNADNS_PAT" \
	  -H "Content-type: application/json" 
	echo;

}
createhostrecord() {
	local PAT="$1";
	local DOM="$2";
	local NAM="$3";
	local IP="$4";
	local TYP="$5";

	if test -z "$TYP"; then
		TYP="A";
	fi

	URL="https://api.gandi.net/v5/livedns/domains/$DOM/records/$NAM" \

	curl -sS -X POST \
	  "$URL" \
	  -H "Authorization: Bearer $GANDI_DYNADNS_PAT" \
	  -H "Content-type: application/json" -d '{"rrset_type":"'$TYP'","rrset_values":["'$IP'"],"rrset_ttl":300}'
	echo;
}
updatehostrecord() {
	local PAT="$1";
	local DOM="$2";
	local NAM="$3";
	local IP="$4";
	local TYP="$5";

	if test -z "$TYP"; then
		TYP="A";
	fi

	URL="https://api.gandi.net/v5/livedns/domains/$DOM/records/$NAM" \

	curl -sS -X PUT \
	  "$URL" \
	  -H "Authorization: Bearer $GANDI_DYNADNS_PAT" \
	  -H "Content-type: application/json" -d '{"rrset_type":"'$TYP'","rrset_values":["'$IP'"],"rrset_ttl":300}'
	echo;
}

