#!/bin/bash

FILE=smb_endpoints
OUT_FILE=smb_check_no_auth
AUTH_FILE=

INFO="[ \033[1;33m=\033[0m ] "
SUCCESS="[ \033[1;32m+\033[0m ] "
FAIL="[ \033[1;31m!\033[0m ] "

while read p; do
	if [ -z "$AUTH_FILE" ]; then
		echo -e "$INFO Now testing server at $p without credentials"
		COMMAND="smbclient -N -L $p 2>/dev/null"
	else
		echo -e "$INFO Now testing server at $p with credentials from $AUTH_FILE"
		COMMAND="smbclient -L $p -A $AUTH_FILE 2>/dev/null"
	fi
	RESULT=$(eval $COMMAND)
	if [[ $RESULT == *"NT_STATUS_ACCESS_DENIED"* ]]; then
		echo -e "$FAIL Access to server at $p was denied. Continuing."
	elif [[ $RESULT == *"NT_STATUS_LOGON_FAILURE"* ]]; then
		echo -e "$FAIL Log on to server at $p failed. Continuing."
	elif [[ $RESULT == *"NT_STATUS_IO_TIMEOUT"* ]]; then
		echo -e "$FAIL Connection to server at $p timed out. Continuing."
	elif [[ $RESULT == *"NT_STATUS_CONNECTION_REFUSED"* ]]; then
		echo -e "$FAIL Connection to server at $p refused. Continuing."
	elif [[ $RESULT == *"NT_STATUS_ACCOUNT_DISABLED"* ]]; then
		echo -e "$FAIL The account was disabled for connecting to $p. Continuing."
	elif [[ $RESULT == *"NT_STATUS_UNSUCCESSFUL"* ]]; then
		echo -e "$FAIL The connection to $p was unsuccessful. Continuing."
	elif [[ $RESULT == *"NT_STATUS_CONNECTION_DISCONNECTED"* ]]; then
		echo -e "$FAIL The connection to $p was disconnected... Continuing."
	elif [[ $RESULT == *"ERRDOS"* ]]; then
		echo -e "$FAIL Protocol negotiation to $p failed. Continuing."
	else
		echo -e "$SUCCESS Access to server at $p granted!"
		SHARES=$(echo "$RESULT" | awk '/Sharename/,/Server               Comment/' | egrep -v "Sharename       |---|Server               |^$" | grep -v "Anonymous login" | grep -v "NT_STATUS_RESOURCE_NAME_NOT_FOUND" | grep -v "NetBIOS over TCP" | awk '{print $1}')
		while read -r line; do
			if [ -z "$AUTH_FILE" ]; then
				echo -e "$INFO Testing \\\\\\\\$p\\\\$line without credentials"
				COMMAND="smbclient -N \\\\\\\\$p\\\\$line -c ls 2>/dev/null"
			else
				echo -e "$INFO Testing \\\\\\\\$p\\\\$line with credentials from $AUTH_FILE"
				COMMAND="smbclient -A $AUTH_FILE \\\\\\\\$p\\\\$line -c ls 2>/dev/null"
			fi
			SHARE_RESULT=$(eval $COMMAND)
			echo "$COMMAND" >> smbclient_responses
			echo "$SHARE_RESULT" >> smbclient_responses
			if [[ $SHARE_RESULT == *"NT_STATUS_ACCESS_DENIED"* ]]; then
				echo -e "$FAIL Access denied to \\\\\\\\$p\\\\$line."
			elif [[ $SHARE_RESULT == *"NT_STATUS_BAD_NETWORK_NAME"* ]]; then
				echo -e "$FAIL Bad network name error returned when accessing \\\\\\\\$p\\\\$line. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_IO_TIMEOUT"* ]]; then
				echo -e "$FAIL Connection to \\\\\\\\$p\\\\$line timed out. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_WRONG_PASSWORD"* ]]; then
				echo -e "$FAIL Received wrong password error for \\\\\\\\$p\\\\$line... Weird. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_NO_MEDIA_IN_DEVICE"* ]]; then
				echo -e "$FAIL No media found in device at \\\\\\\\$p\\\\$line. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_LOGON_FAILURE"* ]]; then
				echo -e "$FAIL Logon failure thrown for \\\\\\\\$p\\\\$line. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_ACCESS_DENIED"* ]]; then
				echo -e "$FAIL Access denied for \\\\\\\\$p\\\\$line. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS_NETWORK_ACCESS_DENIED"* ]]; then
				echo -e "$FAIL Network access denied for \\\\\\\\$p\\\\$line. Continuing."
			elif [[ $SHARE_RESULT == *"NT_STATUS"* ]]; then
				echo -e "$FAIL Unexpected NT_STATUS error thrown for \\\\\\\\$p\\\\$line. Continuing."
			else
				echo -e "$SUCCESS Access granted to \\\\\\\\$p\\\\$line!"
				echo "$p $line \\\\$p\\$line" >> $OUT_FILE
			fi
		done <<< "$SHARES"
	fi
done <$FILE

echo -e "$SUCCESS All done! Results written to file at $OUT_FILE. Exiting."
