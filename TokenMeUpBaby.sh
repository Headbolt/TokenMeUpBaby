#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#	TokenMeUpBaby.sh
#	https://github.com/Headbolt/TokenMeUpBaby
#
#   This Script is designed for use in JAMF
#
#   - This script will ...
#			Detect if the JAMF Management Account has a Secure Token, and add it if not.
#
###############################################################################################################################################
#
# HISTORY
#
#	Version: 1.2 - 19/02/2023
#
#	- 15/03/2018 - V1.0 - Created by Headbolt
#
#   - 21/10/2019 - V1.1 - Updated by Headbolt
#							More comprehensive error checking and notation
#
#   - 19/02/2023 - V1.2 - Updated by Headbolt
#							Removed a lot of now extraneous inputs, variables and settings
#
###############################################################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
adminUser=$4 # Grab the username for the admin user we will use to change the password from JAMF variable #4 eg. username
adminPass=$5 # Grab the password for the admin user we will use to change the password from JAMF variable #5 eg. password
User=$6 # Grab the username for the user we want to create a token for from JAMF variable #6 eg. username
Pass=$7 # Grab the password for the user we want to create a token for from JAMF variable #7 eg. password
#
ExitCode=0 # Set Initial ExitCode
#ScriptName="append prefix here as needed | Enable Secure Token on Account"
ScriptName="Security | Enable Secure Token on Account" # Set the name of the script for later logging
#
###############################################################################################################################################
#
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# TokenCheck Function
#
TokenCheck(){
#
/bin/echo 'Grabbing Secure Token Status for all relevant Accounts'
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
ADMINstatus=$(sysadminctl -secureTokenStatus $adminUser 2>&1)
ADMINtoken=$(echo $ADMINstatus | awk '{print $7}')
/bin/echo "Admin Account for this process ( $adminUser ) secureTokenStatus = $ADMINtoken"
#
USERstatus=$(sysadminctl -secureTokenStatus $User 2>&1)
USERtoken=$(echo $USERstatus | awk '{print $7}')
/bin/echo "User Account for this process ( $User ) secureTokenStatus = $USERtoken"
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
#
/bin/echo Ending Script '"'$ScriptName'"'
#
/bin/echo # Outputting a Blank Line for Reporting Purposes
/bin/echo  ----------------------------------------------- # Outputting a Dotted Line for Reporting Purposes
/bin/echo # Outputting a Blank Line for Reporting Purposes
exit $ExitCode
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
#
# Beginning Processing
#
###############################################################################################################################################
#
/bin/echo # Outputs a blank line for reporting purposes
SectionEnd
# 
Stamp=$(date)
/bin/echo $Stamp #Display Current Time
/bin/echo # Outputting a Blank Line for Reporting Purposes
#
/bin/echo 'Checking Initial Token States'
SectionEnd
#
TokenCheck
SectionEnd
#
TokenSetProceed=$(/bin/echo NO)
#
if [ $ADMINtoken == "ENABLED" ]
	then
		TokenSetProceed=$(echo YES)
fi
#
if [ $TokenSetProceed == "YES" ]
	then
		#
		/bin/echo 'ensuring '$adminUser' account is temporarily a local Admin'
		dseditgroup -o edit -a $adminUser admin
		/bin/echo # Outputs a blank line for reporting purposes
		/bin/echo 'Enabling '$User' with a Secure Token'
		/bin/echo 'Enabling using '$adminUser' as the AdminUser'
		/bin/echo # Outputs a blank line for reporting purposes
		sysadminctl -adminUser $adminUser -adminPassword $adminPass -secureTokenOn $User -password $Pass 
		SectionEnd
fi
#       
/bin/echo 'Checking New Token States'
#
TokenCheck
#
SectionEnd
ScriptEnd
