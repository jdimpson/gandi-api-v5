#!/bin/sh

# this script uses the liveDNS API, not the Domain API, at least currently
# https://api.gandi.net/docs/livedns/

haserrors() {
	local STR="$1";
	local jqstr='select(.status == "error")';

	if test -z "$STR"; then
		jq -e "$jqstr" > /dev/null 2>&1;
	else
		echo "$STR" | jq -e "$jqstr" > /dev/null 2>&1;
	fi
}

errorreasons() {
	local STR="$1";
	local jqstr='.errors[].description'
	if test -z "$STR"; then
		jq -r "$jqstr" 2> /dev/null;
	else
		echo "$STR" | jq -r "$jqstr" 2> /dev/null;
	fi
}

hashttpcode() {
	local STR="$1";
	local jqstr='select(.code)';

	if test -z "$STR"; then
		jq -e "$jqstr" > /dev/null 2>&1;
	else
		echo "$STR" | jq -e "$jqstr" > /dev/null 2>&1;
	fi
}
gethttpcode() {
	local STR="$1";
	local jqstr='.code';
	if test -z "$STR"; then
		jq -r "$jqstr" 2> /dev/null;
	else
		echo "$STR" | jq -r "$jqstr" 2> /dev/null;
	fi
}

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
	  -H "Authorization: Bearer $PAT" \
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
	  -H "Authorization: Bearer $PAT" \
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

	DATA='{"rrset_type":"'$TYP'","rrset_values":["'$IP'"],"rrset_ttl":300}'

	curl -sS -X POST \
	  "$URL" \
	  -H "Authorization: Bearer $PAT" \
	  -H "Content-type: application/json" -d "$DATA";
	echo;
}
updatehostrecord() {
	local PAT="$1";
	local DOM="$2";
	local NAM="$3";
	local IP="$4";
	local TYP="$5";

	# XXX: this only supports setting a single record of single type. would be nice to handle mutiple records

	if test -z "$TYP"; then
		TYP="A";
	fi

	URL="https://api.gandi.net/v5/livedns/domains/$DOM/records/$NAM" \

	curl -sS -X PUT \
	  "$URL" \
	  -H "Authorization: Bearer $PAT" \
	  -H "Content-type: application/json" -d '{"items":[{"rrset_type":"'$TYP'","rrset_values":["'$IP'"],"rrset_ttl":300}]}'
	echo;
}

