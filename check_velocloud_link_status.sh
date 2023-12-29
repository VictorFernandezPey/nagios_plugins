#!/bin/bash

#######################################
#######################################
### ______    ______   ___     ___  ###
### | ___ \   | ____|  \  \  /  /   ###
### | |_/ /   | |__     \  \/  /    ###
### | |__/    | ___|     \    /     ###
### | |       | |___      |  |      ###
### \_|       |_____|     |__|      ###
#######################################
#######################################

# Initialize variables
HOST=""
COMMUNITY=""
INTERFACE=""

# Help function
function show_help {
    echo "Use: $0 -h <host> -c <community> -i <interface name>"
    echo "Example: ./check_snmp_plugin.sh -h 10.2.1.116 -c ConsolCXjd -i GE5"
    exit 1
}

# Parse options
while getopts "h:c:i:" opt; do
    case $opt in
        h)
            HOST=$OPTARG
            ;;
        c)
            COMMUNITY=$OPTARG
            ;;
        i)
            INTERFACE=$OPTARG
            ;;
        *)
            show_help
            ;;
    esac
done

# Verify that all required options are present
if [ -z "$HOST" ] || [ -z "$COMMUNITY" ] || [ -z "$INTERFACE" ]; then
    show_help
fi

# Evaluate different INTERFACE values
if [[ "$INTERFACE" == "GE3" ]]; then
    OID="SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0.3"
elif [[ "$INTERFACE" == "GE4" ]]; then
    OID="SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0.4"
elif [[ "$INTERFACE" == "GE5" ]]; then
    OID="SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0.5"
elif [[ "$INTERFACE" == "GE6" ]]; then
    OID="SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0.6"
elif [[ "$INTERFACE" == "GE7" ]]; then
    OID="SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0.7"
else
    # Manage other INTERFACES
    STATUS="UNKNOWN"
fi

# Perform SNMP query
RESULT=$(snmpwalk -v2c -c $COMMUNITY $HOST $OID)

VELO_ERROR_CODE=${RESULT: -1}

# Analyze the result
STATUS="UNKNOWN"
if [[ "$RESULT" == *"INTEGER: 7"* ]]; then
    STATUS="OK"
    RESULT="Link UP, Active State"
    echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
    exit 0
elif [[ "$RESULT" == *"INTEGER: 5"* ]]; then
    STATUS="OK"
    RESULT="Link UP, Standby State"
    echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
    exit 0
elif [[ "$RESULT" == *"INTEGER: 6"* ]]; then
    STATUS="DEGRADED"
    RESULT="Link UP, Degraded State"
    echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
    exit 1
else
    STATUS="CRITICAL"
    RESULT="Link is DOWN"
    echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
    exit 2
fi
