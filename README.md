# gandi-api-v5
Simple scripts for working with the Gandi API as documented at https://api.gandi.net/docs/

## Dynamic DNS

[dynadns.sh](dynadns.sh)

Note that Gandi's minimum TTL is 300 seconds, so I wouldn't advise using their service for this purpose (and neither would they, I imagine). But it works fine if your IP address rarely changes and you can
tolerate 5 minutes of delay on return-to-service.

This script and any future script expect to find an environmental variable called GANDI_DYNADNS_PAT
set to the token created via their Personal Access Token (PAT). You can create your PAT in your Gandi account using [these](https://api.gandi.net/docs/authentication/) instructions.
 
WHen you create a PAT, it will need the "Manage domain name technical configurations" permission. (In future, it might also need "See and renew domain names" and "See Cloud resources", but currently does not.) You should name the PAT "dynadns". Right now the PAT name is not important to the script, but might be in future.

## Function library

[gandi_v5_funcs.sh](gandi_v5_funcs.sh)

Currently only implements a minority of Gandi's [LiveDNS API](https://api.gandi.net/docs/livedns/).
