#!/bin/sh

# Nagios "check" for querying output of scripts
# from remote servers via SNMP "extend" mechanism.
# 
# Author Michal Ludvig <michal@logix.cz> (c) 2006
#        http://www.logix.cz/michal/devel/nagios
# 

# Example configuration 
# =====================
# for monitoring SW RAID arrays. Any other service
# that can be checked with a script can be monitored
# with this approach.
# 
# Put the following lines into nagios' configuration:
# 
# ---- cut here ----
# $USER10$=/usr/local/nagios/libexec.local
# 
# define command{
# 	command_name	check_snmp_extend
# 	command_line	$USER10$/check_snmp_extend.sh $HOSTADDRESS$ $ARG1$
# 	}
# 
# define service{
# 	use			generic-service
# 	host_name		server.domain
# 	service_description	RAID status
# 	check_command		check_snmp_extend!raid-md0
# }
# ---- cut here ----
# 
# On the host server.domain configure SNMP extension
# with name "raid-md0". 
# Configuration goes to /etc/snmp/snmpd.conf or similar.
# 
# ---- cut here ----
# extend raid-md0 /usr/local/bin/nagios-linux-swraid.pl --device=md0
# ---- cut here ----
# 
# That's all. Just note that older versions of 
# Net-SNMP package did not support "extend" keyword.
# You will have to use "exec" with check_snmp_exec.sh
# 
# Both check_snmp_exec.sh and nagios-linux-swraid.pl
# scripts are available from:
#    http://www.logix.cz/michal/devel/nagios
# 
# Enjoy!
# Michal Ludvig

. /usr/lib64/nagios/plugins/utils.sh || exit 3

SNMPGET=$(which snmpget)

test -x ${SNMPGET} || exit $STATE_UNKNOWN

HOST=$1
shift
NAME=$1

test "${HOST}" -a "${NAME}" || exit $STATE_UNKNOWN

SELFDIRNAME=$(dirname $0)
test -n "${SELFDIRNAME}" && SELFDIRNAME="${SELFDIRNAME}/"
HOST_ARG=$(${SELFDIRNAME}resolve-v4v6.pl --host ${HOST} --wrap-v6)

RESULT=$(${SNMPGET} -v2c -c public -OvQ ${HOST_ARG} NET-SNMP-EXTEND-MIB::nsExtendOutputFull.\"${NAME}\" 2>&1)

STATUS=$(echo $RESULT | awk -F[\ \:\-] '{print $1}')

case "$STATUS" in
	OK|WARNING|CRITICAL|UNKNOWN)
		RET=$(eval "echo \$STATE_$STATUS")
		;;
	*)
		RET=$STATE_UNKNOWN
		RESULT="UNKNOWN - SNMP returned unparsable status: $RESULT"
		;;
esac

echo $RESULT
exit $RET
