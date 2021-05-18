#!/bin/bash

#Utils
sudo apt update
sudo apt-get install -y unzip jq

#Get IP
local_ipv4=`echo $(curl -s -f -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface?api-version=2019-06-01" | jq -r '.[1].ipv4[]' | grep private | awk '{print $2}' | awk -F \" '{print $2}') | awk '{print $1}'`

#Download Consul
CONSUL_VERSION="1.9.0"
curl --silent --remote-name https://releases.hashicorp.com/consul/1.9.0/consul_1.9.0_linux_amd64.zip

#Install Consul
unzip consul_1.9.0_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

#Create Consul User
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl
[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

cat << EOF > /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
ui = true
EOF

cat << EOF > /etc/consul.d/client.hcl
advertise_addr = "$local_ipv4"
retry_join = ["${consul_ip}"]
EOF

cat << EOF > /etc/consul.d/nginx.json
{
  "service": {
    "name": "nginx",
    "port": 80,
    "checks": [
      {
        "id": "nginx",
        "name": "nginx TCP Check",
        "tcp": "localhost:80",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status

#Install Dockers
#sudo snap install docker
#sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#sudo chmod +x /usr/local/bin/docker-compose

#Run  nginx
#sleep 10
#cat << EOF > docker-compose.yml
#version: "3.7"
#services:
#  web:
#    image: nginxdemos/hello
#    ports:
#    - "80:80"
#    restart: always
#    command: [nginx-debug, '-g', 'daemon off;']
#    network_mode: "host"
#EOF
#sudo docker-compose up -d

sudo apt update && sudo apt install -y nginx && sudo apt install -y php-fpm && sudo apt install -y php-curl && sudo /etc/init.d/php7.2-fpm restart && sudo rm /etc/nginx/sites-available/default
cat << EOF > /etc/nginx/sites-available/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php$ {
          fastcgi_pass unix:/run/php/php7.2-fpm.sock;
          include snippets/fastcgi-php.conf; 
        }
}
EOF

cat << EOF > /var/www/html/index.php
<?php
\$page = \$_SERVER['PHP_SELF'];
\$sec = "5";
\$t=time();
echo "<center><b>";
echo "<h1>Application ${app_id} Scaling Operations Status</h1>";
echo "<br>";
echo(date("m-d-Y   H:i:s",\$t));
echo "</b></center><br>";
\$url1 = array("Scaling operation active? " => "http://${consul_ip}:8500/v1/kv/adpm/applications/${app_id}/scaling/is_running?raw");
\$url2 = array("Current backend workload count: " => "http://${consul_ip}:8500/v1/kv/adpm/applications/${app_id}/scaling/workload/current_count?raw");
\$url3 = array("Last workload scaling event timestamp: " => "http://${consul_ip}:8500/v1/kv/adpm/applications/${app_id}/scaling/workload/last_modified_timestamp?raw");
\$url4 = array("Current BIG-IP cluster count: " => "http://${consul_ip}:8500/v1/kv/adpm/applications/${app_id}/scaling/bigip/current_count?raw");
\$url5 = array("Last BIG-IP scaling event timestamp" => "http://${consul_ip}:8500/v1/kv/adpm/applications/${app_id}/scaling/bigip/last_modified_timestamp?raw");

\$urls = array_merge(\$url1, \$url2, \$url3, \$url4, \$url5);
\$array_length = count(\$urls);
\$ch = curl_init();
echo "<center><table cellpadding=10 border=5 bordercolor='#0000ff'><tr><td valign='middle' style='text-align:left'>";
foreach (\$urls as \$x => \$x_value)
{
  echo "<br>" . \$x;
  \$headers    = [];
  \$headers[]  = 'X-Consul-Token: 6ae6afa6-a8f3-06ba-b960-515c7963d23a';
  curl_setopt(\$ch, CURLOPT_HTTPHEADER, \$headers);
  curl_setopt(\$ch, CURLOPT_URL, \$x_value);
  curl_setopt(\$ch, CURLOPT_HEADER, false);
  curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, false);
  curl_setopt(\$ch, CURLOPT_VERBOSE, true);

  echo "&nbsp";

  curl_exec(\$ch);
}
echo "</td></tr></table></center>";
curl_close(\$ch);
?>

<html>
    <head>
    <meta http-equiv="refresh" content="<?php echo \$sec?>;URL='<?php echo \$page?>'">
    </head>
    <?php
    ?>
</html>
EOF
sudo /etc/init.d/php7.2-fpm restart && sudo systemctl restart nginx



