#!/bin/bash

#Script to run return to service on Jamf Pro
#Currently the only way to run this feature is via the API
#This script is built for devices already in ADE as it does not tell the device what MDM Profile to install, only a wi-fi profile
#You can elect to hard code any of the variables as desired, the intent was to create the ability to pass the script around to anyone to try
#This was last confirmed operational on 9/19/23

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#        * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#           notice, this list of conditions and the following disclaimer in the
#           documentation and/or other materials provided with the distribution.
#         * Neither the name of the JAMF Software, LLC nor the
#           names of its contributors may be used to endorse or promote products
#           derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

echo "Please enter your API credentials"
read -p 'Username: ' APIUSER
read -sp 'Password: ' APIPASS
echo -e "\n Please enter your full server URL starting with https://"
read -p 'ServerURL: ' url

#HARD CODED VARIABLE FOR API BEARER TOKEN RETRIEVAL
getBearerToken() {
	response=$(curl -s -u "$APIUSER":"$APIPASS" "$url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
}

getBearerToken 

#Management ID can be seen in the device record
echo -e "\n Please enter the ManagementId of the device you would like to return to service:"
read -p 'ManagementId: ' managementId
#Download the .mobileconfig file for the wi-fi you want and enter the file path or drag and drop it when prompted
echo -e "\n Please enter the file path of the Wi-Fi Configuration Profile you would like to use:"
read -p 'configProfilePath: ' configProfilePath

# define it
base64pathwifi=$(base64 < "$configProfilePath")

curl --request POST \
--url "$url"/api/preview/mdm/commands \
--header "Authorization: Bearer $bearerToken" \
--header 'accept: application/json' \
--header 'content-type: application/json' \
--data '
{
	"clientData": [
		{
			"managementId": "'$managementId'"
		}
	],
	"commandData": {
		"commandType": "ERASE_DEVICE",
		"returnToService": {
			"enabled": true,
			"wifiProfileData": "'$base64pathwifi'"
		}
	}
}
'
