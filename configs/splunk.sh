#!/bin/bash
echo
echo '##############################################'
echo '#                                            #'
echo '# Welcome to the Splunk 7.0.2 auto-installer #'
echo '# for CentOS 7 x64.                          #'
echo '# Last updated 03/12/2018.                   #'
echo '# Enter the "splunk" linux user account      #'
echo '# password and press enter to let the magic  #'
echo '# happen. Note: You will change the Splunk   #'
echo '# Web admin password upon first login.       #'
echo '#                                            #'
echo '##############################################'
echo
echo
echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
echo "[Unit]" > /etc/systemd/system/disable-thp.service
echo "Description=Disable Transparent Huge Pages" >> /etc/systemd/system/disable-thp.service
echo "" >> /etc/systemd/system/disable-thp.service
echo "[Service]" >> /etc/systemd/system/disable-thp.service
echo "Type=simple" >> /etc/systemd/system/disable-thp.service
echo 'ExecStart=/bin/sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo never > /sys/kernel/mm/transparent_hugepage/defrag"' >> /etc/systemd/system/disable-thp.service
echo "Type=simple" >> /etc/systemd/system/disable-thp.service
echo "" >> /etc/systemd/system/disable-thp.service
echo "[Install]" >> /etc/systemd/system/disable-thp.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/disable-thp.service
systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp
echo
echo "Transparent Huge Pages (THP) Disabled."
echo
ulimit -n 64000
ulimit -u 20480
echo "DefaultLimitFSIZE=-1" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=64000" >> /etc/systemd/system.conf
echo "DefaultLimitNPROC=20480" >> /etc/systemd/system.conf
echo
echo "ulimit Increased."
echo
yum install wget -y
cd /tmp
wget -O splunk-7.0.2-03bbabbd5c0f-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.0.2&product=splunk&filename=splunk-7.0.2-03bbabbd5c0f-Linux-x86_64.tgz&wget=true'
echo
echo "Splunk Downloaded."
echo
tar -xzvf /tmp/splunk-7.0.2-03bbabbd5c0f-Linux-x86_64.tgz -C /opt
rm -f /tmp/splunk-7.0.2-03bbabbd5c0f-Linux-x86_64.tgz
useradd splunk
echo splunk:F5demonet! > /tmp/pwdfile
cat /tmp/pwdfile | chpasswd
rm -f /tmp/pwdfile
echo
echo "Splunk installed and splunk linux user created."
echo
echo "[settings]" > /opt/splunk/etc/system/local/web.conf
echo "enableSplunkWebSSL = true" >> /opt/splunk/etc/system/local/web.conf
echo
echo "HTTPS enabled for Splunk Web using self-signed certificate."
echo
chown -R splunk:splunk /opt/splunk
afz=`firewall-cmd --get-active-zone | head -1`
firewall-cmd --zone=$afz --add-port=8000/tcp --permanent
firewall-cmd --zone=$afz --add-port=8065/tcp --permanent
firewall-cmd --zone=$afz --add-port=8089/tcp --permanent
firewall-cmd --zone=$afz --add-port=8191/tcp --permanent
firewall-cmd --zone=$afz --add-port=9997/tcp --permanent
firewall-cmd --zone=$afz --add-port=8080/tcp --permanent
firewall-cmd --zone=$afz --add-port=10514/udp --permanent
firewall-cmd --reload
echo
echo "Firewall ports used by Splunk opened."
echo "[splunktcp]" > /opt/splunk/etc/system/local/inputs.conf
echo "[splunktcp://9997]" >> /opt/splunk/etc/system/local/inputs.conf
echo "index = main" >> /opt/splunk/etc/system/local/inputs.conf
echo "disabled = 0" >> /opt/splunk/etc/system/local/inputs.conf
echo "" >> /opt/splunk/etc/system/local/inputs.conf
echo "[udp://10514]" >> /opt/splunk/etc/system/local/inputs.conf
echo "index = main" >> /opt/splunk/etc/system/local/inputs.conf
echo "disabled = 0" >> /opt/splunk/etc/system/local/inputs.conf
chown splunk:splunk /opt/splunk/etc/system/local/inputs.conf
echo
echo "Enabled Splunk TCP input over 9997 and UDP traffic input over 10514."
echo
runuser -l splunk -c '/opt/splunk/bin/splunk start --accept-license'
/opt/splunk/bin/splunk enable boot-start -user splunk
runuser -l splunk -c '/opt/splunk/bin/splunk stop'
chown root:splunk /opt/splunk/etc/splunk-launch.conf
chmod 644 /opt/splunk/etc/splunk-launch.conf
echo
echo "Splunk test start and stop complete. Enabled Splunk to start at boot. Also, adjusted splunk-launch.conf to mitigate privilege escalation attack."
echo
runuser -l splunk -c '/opt/splunk/bin/splunk start'
if [[ -f /opt/splunk/bin/splunk ]]
        then
                echo Splunk Enterprise
                cat /opt/splunk/etc/splunk.version | head -1
                echo "has been installed, configured, and started!"
                echo "Visit the Splunk server using https://hostNameORip:8000 as mentioned above."
                echo
                echo
                echo "                        HAPPY SPLUNKING!!!"
                echo
                echo
                echo
        else
                echo Splunk Enterprise has FAILED install!
fi
#End of File
