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
#			The Following Variables should be defined
#			Variable 4 - Named "Current Secure Token Admin User - eg. AdminUser"
#			Variable 5 - Named "Current Secure Token Admin Password - eg. PasswordyThing"
#
# 			Note, as of V1.4, if Variable 5 "Current Secure Token Admin Password" is set to "Admin Password"
#					It will be assumed you are trying to pull the Admin User password from a JAMF Extension Attribute
#					with that name

#			Variable 6 - Named "New Secure Token User - eg. User"
#			Variable 7 - Named "New Secure Token User Password - eg. AnotherPasswordyThing"
#
# 			Note, as of V1.3, if Variable 7 "New Secure Token User" is set to "JamfManagementAccount!!"
#					It will be assumed you are trying to grant the JAMF Management Account a Secure Token
#					In which case the below variables MUST be set
#
#			Variable 8 - Named "API URL - eg. https://mycompany.jamfcloud.com"
#			Variable 9 - Named "API User - eg. API-User"
#			Variable 10 - Named "API User Password - eg. YetAnotherPasswordyThing"
#
#			The API User set in Variable 9 will need the following permisions ONLY
#			Jamf Pro Server Objects > Read perms for Computers
#			Jamf Pro Server Actions > View Local Admin Password
#
###############################################################################################################################################
#
# HISTORY
#
#	Version: 1.4 - 10/01/2024
#
#	- 15/03/2018 - V1.0 - Created by Headbolt
#
#   - 21/10/2019 - V1.1 - Updated by Headbolt
#							More comprehensive error checking and notation
#
#   - 19/02/2023 - V1.2 - Updated by Headbolt
#							Removed a lot of now extraneous inputs, variables and settings
#
#   - 08/09/2023 - V1.3 - Updated by Headbolt
#							Updated to allow for retrieval of the JAMF Management account password via the API
#
#   - 10/01/2024 - V1.4 - Updated by Headbolt1
#							Updated to allow for retrieval of the local Admin password via the API
#
###############################################################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
adminUser=${4} # Grab the username for the admin user we will use to change the password from JAMF variable #4 eg. username
adminPass=${5} # Grab the password for the admin user we will use to change the password from JAMF variable #5 eg. password
User=${6} # Grab the username for the user we want to create a token for from JAMF variable #6 eg. username
Pass=${7} # Grab the password for the user we want to create a token for from JAMF variable #7 eg. password
apiURL=${8} # Grab the username for API Login from JAMF variable #8 eg. username
apiUser=${9} # Grab the password for API Login from JAMF variable #9 eg. password
apiPass=${10} # Grab the username for FileVault unlock from JAMF variable #10 eg. username
#
udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }') # Grab UUID of machine
#
ScriptName="Security | Enable Secure Token on Account" # Set the name of the script for later logging
ExitCode=0 # Set Initial ExitCode
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
# Verifiy all Required Parameters are set.
#
ParameterCheck(){
#
/bin/echo 'Checking parameters.'
#
# Verify all parameters are present
#
if [ "$adminUser" == "" ]
	then
	    /bin/echo "Error:  The parameter 'FileVault Admin User' is blank.  Please specify a user to reset."
		ExitCode=1
		ScriptEnd
fi
#
if [ "$adminPass" == "" ]
	then
	    /bin/echo "Error:  The parameter 'FileVault Admin Password' is blank.  Please specify a user to reset."
		ExitCode=1
		ScriptEnd
fi
#
if [ "$User" == "" ]
	then
		/bin/echo "Error:  The parameter 'Target User' is blank.  Please specify a user."
		ExitCode=1
		ScriptEnd
fi
#
if [ "$Pass" == "" ]
	then
		/bin/echo "Error:  The parameter 'Target User' is blank.  Please specify a password."
		ExitCode=1
		ScriptEnd
fi
#
if [ "$Pass" == "JamfManagementAccount!!" ]
	then
		if [ "$apiURL" == "" ]
			then
			    /bin/echo "Error:  The parameter 'API URL' is blank.  Please specify a URL."
				ExitCode=1
				ScriptEnd
		fi
		#
		if [ "$apiUser" == "" ]
			then
			    /bin/echo "Error:  The parameter 'API Username' is blank.  Please specify a user."
				ExitCode=1
				ScriptEnd
		fi
		#
		if [ "$apiPass" == "" ]
			then
			    /bin/echo "Error:  The parameter 'API Password' is blank.  Please specify a password."
				ExitCode=1
				ScriptEnd
		fi
fi
#
/bin/echo 'Parameters Verified.'
#
}
#
###############################################################################################################################################
#
# Auth Token Function
#
AuthToken (){
#
/bin/echo 'Getting Athentication Token from JAMF'
rawtoken=$(curl -s -u ${apiUser}:${apiPass} -X POST "${apiURL}/uapi/auth/tokens" | grep token) # This Authenticates against the JAMF API with the Provided details and obtains an Authentication Token
rawtoken=${rawtoken%?};
token=$(echo $rawtoken | awk '{print$3}' | cut -d \" -f2)
#
}
#
###############################################################################################################################################
#
# Get Management Account Password Function
#
GetManagementAccountPassword (){
#
sernum=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}') # Grab Device Serial Number
/bin/echo 'Grabbing Device Serial Number : "'$sernum'"'
/bin/echo 'Grabbing Device ID in JAMF'
jamfdeviceId=$(curl -s -X GET "${apiURL}/JSSResource/computers/serialnumber/$sernum/subset/general" -H 'Authorization: Bearer '$token'' | xpath -e '/computer/general/id/text()' )
/bin/echo 'Device ID in JAMF : "'$jamfdeviceId'"'
jamfdevicemanagementId=$(curl -s -X GET "${apiURL}/api/v1/computers-inventory-detail/${jamfdeviceId}" -H 'Authorization: Bearer '$token'' | grep "managementId" | awk '{ print $3 }' | cut -c 2-37 )  
/bin/echo 'Grabbing Management ID in JAMF : "'$jamfdevicemanagementId'"'
Pass=$(curl -s -X GET "${apiURL}/api/v2/local-admin-password/$jamfdevicemanagementId/account/JAMF/password" -H 'Authorization: Bearer '$token'' | awk '{ print $3 }' | rev | cut -c 2- | rev | cut -c 2- )
/bin/echo 'Grabbing Management Password from JAMF : ....... Not Telling You What It Is.'
#
}
#
###############################################################################################################################################
#
# Verify the current User Password in JAMF LAPS
#
GetAdminPassword (){
#
/bin/echo 'Grabbing Current Password From JAMF API'
currentPass=$(curl -s -X GET "${apiURL}/JSSResource/computers/udid/$udid/subset/extension_attributes" -H 'Authorization: Bearer '$token'' | xpath -e "//extension_attribute[name=$extAttName]" 2>&1 | awk -F'<value>|</value>' '{print $2}')
#
if [ "$currentPass" == "" ]
	then
	    /bin/echo "No Password is stored in LAPS."
	else
	    /bin/echo "A Password was found in LAPS."
fi
#
if [ "$currentPass" != "" ]
	then
		passwdA=`dscl /Local/Default -authonly $adminUser $currentPass`
		if [ "$passwdA" == "" ]
			then
                adminPass=$currentPass
                /bin/echo "Current Password stored in LAPS for User $adminUser is $currentPass"
				/bin/echo "Password stored in LAPS is correct for $adminUser."
			else
				/bin/echo "Error: Password stored in LAPS is not valid for $adminUser."
				/bin/echo "Current Password stored in LAPS for User $adminUser is $currentPass"
				currentPass=""
		fi
fi
}
#
###############################################################################################################################################
#
# Secure TokenCheck Function
#
SecureTokenCheck(){
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
/bin/echo # Outputting a Blank Line for Reporting Purposes
SectionEnd
#
ParameterCheck
SectionEnd
#
if [ "$Pass" == "JamfManagementAccount!!" ]
	then
		/bin/echo 'New User Password is set to "JamfManagementAccount!!"'
		/bin/echo 'This indicates we are attempting to get a secure token for the JAMF Management Account'
		/bin/echo 'Connecting to JAMF to Grab it from the API'
		SectionEnd
		AuthToken
		SectionEnd
		GetManagementAccountPassword
        SectionEnd
fi
#
if [ "$adminPass" == "Administrator Password" ]
	then
		/bin/echo 'Admin User Password is set to "Administrator Password"'
		/bin/echo 'This indicates we are attempting to get a password from JAMF'
		/bin/echo 'Connecting to JAMF to Grab it from the API'
  		extAttName=$(echo "\"${adminPass}"\") # Place " quotation marks around extension attribute name in the variable
		SectionEnd
		AuthToken
		SectionEnd
		GetAdminPassword
        SectionEnd
fi
#
/bin/echo 'Checking Initial Token States'
SectionEnd
#
SecureTokenCheck
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
		/bin/echo 'ensuring "'$adminUser'" account is temporarily a local Admin'
		dseditgroup -o edit -a $adminUser admin
		/bin/echo # Outputs a blank line for reporting purposes
		/bin/echo 'Enabling "'$User'" with a Secure Token'
		/bin/echo 'Enabling using "'$adminUser'" as the AdminUser'
		/bin/echo # Outputs a blank line for reporting purposes
		sysadminctl -adminUser $adminUser -adminPassword $adminPass -secureTokenOn $User -password $Pass 
		SectionEnd
fi
#       
/bin/echo 'Checking New Token States'
SecureTokenCheck
#
SectionEnd
ScriptEnd
