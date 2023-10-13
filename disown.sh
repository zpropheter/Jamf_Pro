#!/bin/bash

url="https://yourserver.jamfcloud.com"
username="username"
password="pasword"
output=$HOME/Desktop/output.txt
#serialnumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )

#Change the serial number to the device you want to disown:

read -p "Please enter the serial number of the device you want to disown: " serialnumber

echo "$serialnumber"

getBearerToken() {
	response=$(curl -s -u "$APIUSER":"$APIPASS" "$url"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

getBearerToken

getEnrollmentCount() {
	deviceEnrollments=$(curl -X 'GET' \
	"$url/api//v1/device-enrollments?page=0&page-size=100&sort=id%3Aasc" \
	-H 'accept: application/json' \
	-H "Authorization: Bearer $bearerToken")
	enrollmentCount=$(/usr/bin/plutil -extract totalCount raw -o - - <<< "$deviceEnrollments")
	echo "Total Enrollments: $enrollmentCount" 
	enrollmentId=$(/usr/bin/plutil -extract "results".0."id" raw -o - - <<< "$deviceEnrollments")
	echo "Enrollment ID: $enrollmentId" 
}

disownDevice() {
	deviceDisowning=$(curl -X 'POST' \
	"$url/api/v1/device-enrollments/$enrollmentId/disown" \
	-H "accept: application/json" \
	-H "Authorization: Bearer $bearerToken" \
	-H "Content-Type: application/json" \
	-d '{
	"devices": [
		"'$serialnumber'"
	]
}')
	echo "$deviceDisowning"
	successCode=$(/usr/bin/plutil -extract devices.$serialnumber raw -o - - <<< "$deviceDisowning")
	echo "$successCode"
}

getEnrollmentCount

if [[ $enrollmentCount != 1 ]]; then
	echo "You have more than one Device Enrollment token configured, this tool does not support Disown for such environments"
else
	disownDevice
	echo "You've been disowned"
fi

#getComputerManagementId() {
#	computerdevicerecord=$(curl -X 'GET' \
#	"$url/api/v1/computers-inventory-detail/$deviceid" \
#	-H 'accept: application/json' \
#	-H "Authorization: Bearer $bearerToken")
#	computermanagementId=$(/usr/bin/plutil -extract "general"."managementId" raw -o - - <<< "$computerdevicerecord")
#	echo "Management ID: $computermanagementId"
#}
#
#getComputerManagementId 
