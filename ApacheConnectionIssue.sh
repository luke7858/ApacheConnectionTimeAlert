#!/bin/bash

###################################
#####Colours######
ESC_SEQ="\x1b["
GREEN=$ESC_SEQ"32;01m"
RED=$ESC_SEQ"31;01m"
RESET=$ESC_SEQ"39;49;00m"
BLUE=$ESC_SEQ"34;01m"
#####Underline/bold#####
BOLD=$ESC_SEQ"\033[1m"
bold=$(tput bold)
UNDERLINE=$ESC_SEQ"\033[4m"
#####################################

maxclientscentos=$(grep MaxClients /etc/httpd/conf/httpd.conf | grep processes -A 1 | awk '{print $2}' | grep -v MaxClients)
 
##################################

neat="################################"
DIST=$(cat /etc/issue | head -1 | cut -d' ' -f1)

printf "$neat\n"
printf "\n"

####################################
check_distro() {
Distro=$(cat /etc/issue | head -1 | cut -d' ' -f1)
if [ $Distro == "CentOS" ] || [ $Distro == "Red Hat" ]; then
        case $Distro in
        "CentOS" )
                Version=$(cat /etc/redhat-release | grep -Eo '[0-9]{1,4}' | head -1)
        ;;
        "Red Hat" )
                Version=$(cat /etc/redhat-release | grep -Eo '[0-9]{1,4}' | head -1)
        ;;
        esac
elif [ $Distro == "Ubuntu"] || [ $Distro == "Debian" ]; then
        case $Distro in
        "Ubuntu" )
                Version=$(cat /etc/issue | head -1 | cut -d' ' -f2 | cut -d'.' -f1)
        ;;
        "Debian" )
                Version=$( cat /etc/issue | head -1 | cut -d' ' -f3 )
        ;;
        esac
fi
}
check_httpd() {
	httpdrunning=$(/etc/init.d/httpd status | grep -ic 'is running')
	httpdport=$(netstat -plnt | grep http | awk '{print $4}' | sed 's/://g')
	if [ ! $httpdport == "" ]; then 
		printf "Apache Port: $httpdport \n"
	else
		printf "Apache Port: No port, Apache not running"
	fi
}
apache_buddy() {
	curl -s apache2buddy.pl | perl > /dev/null 2>&1; #run apache buddy and redirect output to /dev/null, we are only looking for the log files
	ab=$(grep -ohe 'Highest Pct .*' /var/log/apache2buddy.log | awk 'END{print $5}' | sed 's/"//g') #getting the ram % allocation for apache from logs produced above
	abram=$(grep -ohe 'Memory: .*' /var/log/apache2buddy.log | awk 'END{print $2}' | sed 's/"//g')
	currentconcentos=$(ps aux | grep -v grep | grep -ic /usr/sbin/httpd)
	MaxcRecommend=$(grep -ohe 'Reccommended: .*' /var/log/apache2buddy.log | awk 'END{print $2}' | sed 's/"//g')
	MaxcConfigured=$(echo - | awk -v max=$MaxcRecommend -v current=$currentconcentos '{print max - current }')
}
httpd_error_logs() {
    errorlogformat=$(grep ^ErrorLog /etc/httpd/conf/httpd.conf | awk '{print $2}' | sed 's/.*[/]//')
    errorlogcentos=$( grep -ic maxc /var/log/httpd/$errorlogformat )
    zerrorlogcentos=$( zgrep -i maxc /var/log/httpd/error_log* )
}
httpd_calculations() {
httpd_error_logs
difference=$(echo - | awk -v apachebuddy=$MaxcRecommend -v current=$maxclientscentos '{print current - apachebuddy}') #compare 

    case $difference in
    0)
        printf "Recommended connections: $MaxcRecommend\n"
        printf "Configured Max Connections: "$maxclientscentos
    ;;
   
    *)
        printf "Connections is configured correctly!!\n"
      ;;
    esac
   
    case $MaxcConfigured in
    1 ) #change to > 1 because it could be less ####################################################################################################################################
        echo "Reached max connections!!: "$MaxcConfigured
        echo "Warning, config crap"
    ;;
    *)
        echo "Your Current Conenctions: "$currentconcentos
        echo "Difference = "$MaxcConfigured
    ;;    
    esac


#if there is a value configured in apache config file for MaxClients then calculate difference between current connections and configured connections
if [ "$maxclientscentos" != "" ] && [ "$maxclientscentos" -ge 1 ];then
       # maxcdiff=$(echo - | awk -v mc=$maxclientsrecommended -v cc=$currentconcentos '{print mc - cc}')
#    echo "Current Connections "$currentconcentos

            if [ "$MaxcConfigured" -ge 1 ]; then
                echo "MaxClients: Not been reached"
            elif [ "$MaxcConfigured" = [1-9] ]; then
                echo "MaxClients: CLOSE TO LIMIT"
            else
                echo "MaxClients: LIMIT REACHED!"
            fi
# if no value has been added then
else
        echo ""
        echo "MaxClients: No Configured Value In Apache Config File!!"
        echo "Checking with apache buddy..."
fi
    #add awk for maxcdiff=$(awk '{$maxclientscentos - $currentconcentos}')

 
if [ "$errorlogcentos" -ge 1 ]; then
# maxclients may have been hit a previous day, try to incoporate date in the search
        echo "Error logs:"
        echo $errorlogscentos
else #elif
####APACHE BUDDY SECTION####    
        echo ""
        echo "Error Logs: Nothing regarding MaxClients"
        echo "Current RAM allocation to apache: $ab%"
        echo "Apache Max RAM Usage: $abram MB"
 
        case $ab in
        [0-75] )
            echo "apache has been allocated too much ram, this could be causing an issue"
        ;;
        *)
            echo "Apache Configuration: OK!"
        ;;
        esac
#############################
    echo ""
    echo $neat
fi
echo $neat    
}
##################################
method1() {
case $httpdrunning in
 #-----------------------
        0 ) #if apache is not running:
            printf "Not running\n"
            printf "Please troubleshoot further\n"
            printf "\n"
            printf "$neat\n"
#------------------------
        ;;
        1 ) #if apache IS running:
            printf "Apache: is running!\n"
            apache_buddy
            printf "\n"
            httpd_calculations
        ;;
        esac
}
##################################
########Start of code#############
##################################
check_distro

if [ "$Distro" == "CentOS" ] && [ "$Version" -lt 7 ] || [ "$Distro" == "Red Hat" ] && [ "$Version" -lt 7 ]; then

check_httpd
method1
 

elif [ "$Distro" == "Ubuntu" ] && [ "$Version" -gt 12] && [ $Version -lt 14 ]; then


printf "Ubuntu\n"


elif [ "$Distro" = "Debian" ] && [ "$Version" = 7 ]; then



printf "Debian Not Supported Yet\n"



else

echo "Error! Server does not appear to be a supported version of Ubuntu or Centos"
 
fi
###################################
#case $variable in
#
#apache )
#echo "Apache results: "
#echo "Maxclients = "
#echo "Recommended clients= "
#echo "Currently set clients= "
#echo "List of connected IPs= "
#;;
##################################
