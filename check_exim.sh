#!/bin/sh
###############################################
#
# Nagios script to check Exim mail queue status
#
# Copyright 2007, 2008 Ian Yates
#
# NOTE: Depending on your config, the nagios user will probably be 
#       needed to be added to the exim group for this script to function correctly
# 
# See usage for command line switches
# 
# You need to add the following to /etc/sudoers:
# nagios  ALL=NOPASSWD:/usr/local/exim/bin/exim
#
# Created: 2006-07-31 (i.yates@uea.ac.uk)
# Updated: 2007-04-30 (i.yates@uea.ac.uk) - Linux/sudo tweaks
# Updated: 2008-03-26 (i.yates@uea.ac.uk) - Fixed bug in critical/warning level checking which could result in erroneous results.
# Updated: 2008-11-27 (i.yates@uea.ac.uk) - Added GPLv3 licence
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
###############################################
####
# Adresindeki betikten forklandı.http://exchange.nagios.org/directory/Plugins/Email-and-Groupware/Exim/check_eximailqueue/details
#EXIM=Eximin calistirilabilir dosyası
#Eger Kurulu Degilse /usr/ports/securtiyin altından sudo kurulumu yapılması gerekiyor.
#SUDO=sudonun çalıştırılabilir dosya yolu
#Kuyruktaki mesaj sayısı performance data icin output paremetresine eklendi
####
. /usr/local/libexec/nagios/utils.sh


VERSION="1.3"

EXIM=/usr/sbin/exim
SUDO=/usr/local/bin/sudo

FLAG_VERBOSE=FALSE
LEVEL_WARN=""
LEVEL_CRIT=""
RESULT=""
EXIT_STATUS=$STATE_OK


###############################################
#
## FUNCTIONS 
#

## Print usage
usage() {
        echo " check_eximailqueue $VERSION - Nagios Exim mail queue check script"
        echo ""
        echo " Usage: check_eximailqueue -w <warning queue size> -c <critical queue size> [ -v ] [ -h ]"
        echo ""
        echo "           -w  Queue size at which a warning is triggered"
        echo "           -c  Queue size at which a critical is triggered"
        echo "           -v  Verbose output (ignored for now)"
        echo "           -h  Show this page"
        echo ""
}
 
## Process command line options
doopts() {
        if ( `test 0 -lt $#` )
        then
                while getopts w:c:vh myarg "$@"
                do
                        case $myarg in
                                h|\?)
                                        usage
                                        exit;;
                                w)
                                        LEVEL_WARN=$OPTARG;;
                                c)
                                        LEVEL_CRIT=$OPTARG;;
                                v)
                                        FLAG_VERBOSE=TRUE;;
                                *)      # Default
                                        usage
                                        exit;;
                        esac
                done
        else
                usage
                exit
        fi
}


# Write output and return result
theend() {
        echo $RESULT
        exit $EXIT_STATUS
}


#
## END FUNCTIONS 
#

#############################################
#
## MAIN 
#


# Handle command line options
doopts $@

# Do the do
OUTPUT=`$SUDO -u root $EXIM -bpc`
if test -z "$OUTPUT" ; then
        RESULT="Mailqueue WARNING - query returned no output!"
        EXIT_STATUS=$STATE_WARNING
else
        if test "$OUTPUT" -lt "$LEVEL_WARN" ; then
                RESULT="Mailqueue OK - $OUTPUT messages on queue | 'message'=$OUTPUT"
                EXIT_STATUS=$STATE_OK
        else
                if test "$OUTPUT" -ge "$LEVEL_CRIT" ; then 
                        RESULT="Mailqueue CRITICAL - $OUTPUT messages on queue"
                        EXIT_STATUS=$STATE_CRITICAL
                else
                        if test "$OUTPUT" -ge "$LEVEL_WARN" ; then 
                                RESULT="Mailqueue WARNING - $OUTPUT messages on queue"
                                EXIT_STATUS=$STATE_WARNING
                        fi
                fi
        fi
fi

# Quit and return information and exit status
theend