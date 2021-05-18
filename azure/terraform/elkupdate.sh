#!/bin/bash

# Disable stdout
exec 2>/dev/null

setup_passwords() {
  sudo cat << EOF > pass
#!/usr/bin/expect -f

set force_conservative 0  ;# set to 1 to force conservative mode even if
                            # script wasn't run conservatively originally
if {0} {
    set send_slow {1 .1}
    proc send {ignore arg} {
          sleep .1s
          exp_send -s -- $arg
    }
}
set timeout -1
spawn /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
match_max 100000
expect -exact "Initiating the setup of passwords for reserved users elastic,apm_system,kibana,kibana_system,logstash_system,beats_system,remote_monitoring_user.\r
You will be prompted to enter passwords as the process progresses.\r
Please confirm that you would like to continue \[y/N\]"
send -- "y\r"
expect -exact "y\r
\r
\r
Enter password for \[elastic\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[elastic\]: "
send -- "F5demonet!\r"
expect -exact "\r
Enter password for \[apm_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[apm_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Enter password for \[kibana_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[kibana_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Enter password for \[logstash_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[logstash_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Enter password for \[beats_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[beats_system\]: "
send -- "F5demonet!\r"
expect -exact "\r
Enter password for \[remote_monitoring_user\]: "
send -- "F5demonet!\r"
expect -exact "\r
Reenter password for \[remote_monitoring_user\]: "
send -- "F5demonet!\r"
expect eof
EOF
sudo chmod +x ./pass
sudo ./pass 
}

setup_ca() {
sudo cat << EOF > CA
#!/usr/bin/expect -f

set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasn't run conservatively originally
if {0} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}

set timeout -1
spawn /usr/share/elasticsearch/bin/elasticsearch-certutil ca
match_max 100000
expect -exact "This tool assists you in the generation of X.509 certificates and certificate\r
signing requests for use with SSL/TLS in the Elastic stack.\r
\r
The 'ca' mode generates a new 'certificate authority'\r
This will create a new X.509 certificate and private key that can be used\r
to sign certificate when running in 'cert' mode.\r
\r
Use the 'ca-dn' option if you wish to configure the 'distinguished name'\r
of the certificate authority\r
\r
By default the 'ca' mode produces a single PKCS#12 output file which holds:\r
    * The CA certificate\r
    * The CA's private key\r
\r
If you elect to generate PEM format certificates (the -pem option), then the output will\r
be a zip file containing individual files for the CA certificate and private key\r
\r
Please enter the desired output file \[elastic-stack-ca.p12\]: "
send -- "\r"
expect -exact "\r
Enter password for elastic-stack-ca.p12 : "
send -- "F5demonet!\r"
expect eof
EOF
sudo chmod +x ./CA
sudo ./CA
}

setup_cert() {
sudo cat << EOF > cert
#!/usr/bin/expect -f

set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasn't run conservatively originally
if {0} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}

set timeout -1
spawn /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
match_max 100000
expect -exact "This tool assists you in the generation of X.509 certificates and certificate\r
signing requests for use with SSL/TLS in the Elastic stack.\r
\r
The 'cert' mode generates X.509 certificate and private keys.\r
    * By default, this generates a single certificate and key for use\r
       on a single instance.\r
    * The '-multiple' option will prompt you to enter details for multiple\r
       instances and will generate a certificate and key for each one\r
    * The '-in' option allows for the certificate generation to be automated by describing\r
       the details of each instance in a YAML file\r
\r
    * An instance is any piece of the Elastic Stack that requires an SSL certificate.\r
      Depending on your configuration, Elasticsearch, Logstash, Kibana, and Beats\r
      may all require a certificate and private key.\r
    * The minimum required value for each instance is a name. This can simply be the\r
      hostname, which will be used as the Common Name of the certificate. A full\r
      distinguished name may also be used.\r
    * A filename value may be required for each instance. This is necessary when the\r
      name would result in an invalid file or directory name. The name provided here\r
      is used as the directory name (within the zip) and the prefix for the key and\r
      certificate files. The filename is required if you are prompted and the name\r
      is not displayed in the prompt.\r
    * IP addresses and DNS names are optional. Multiple values can be specified as a\r
      comma separated string. If no IP addresses or DNS names are provided, you may\r
      disable hostname verification in your SSL configuration.\r
\r
    * All certificates generated by this tool will be signed by a certificate authority (CA)\r
      unless the --self-signed command line option is specified.\r
      The tool can automatically generate a new CA for you, or you can provide your own with\r
      the --ca or --ca-cert command line options.\r
\r
By default the 'cert' mode produces a single PKCS#12 output file which holds:\r
    * The instance certificate\r
    * The private key for the instance certificate\r
    * The CA certificate\r
\r
If you specify any of the following options:\r
    * -pem (PEM formatted output)\r
    * -keep-ca-key (retain generated CA key)\r
    * -multiple (generate multiple certificates)\r
    * -in (generate certificates from an input file)\r
then the output will be be a zip file containing individual certificate/key files\r
\r
Enter password for CA (elastic-stack-ca.p12) : "
send -- "F5demonet!\r"
expect -exact "\r
Please enter the desired output file \[elastic-certificates.p12\]: "
send -- "\r"
expect -exact "\r
Enter password for elastic-certificates.p12 : "
send -- "F5demonet!\r"
expect eof
EOF
sudo chmod +x ./cert
sudo ./cert
}

setup_http() {
sudo cat << EOF > http
#!/usr/bin/expect -f

set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasn't run conservatively originally
if {0} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}

set timeout -1
spawn /usr/share/elasticsearch/bin/elasticsearch-certutil http
match_max 100000
expect -exact "\r
## Elasticsearch HTTP Certificate Utility\r
\r
The 'http' command guides you through the process of generating certificates\r
for use on the HTTP (Rest) interface for Elasticsearch.\r
\r
This tool will ask you a number of questions in order to generate the right\r
set of files for your needs.\r
\r
## Do you wish to generate a Certificate Signing Request (CSR)?\r
\r
A CSR is used when you want your certificate to be created by an existing\r
Certificate Authority (CA) that you do not control (that is, you don't have\r
access to the keys for that CA). \r
\r
If you are in a corporate environment with a central security team, then you\r
may have an existing Corporate CA that can generate your certificate for you.\r
Infrastructure within your organisation may already be configured to trust this\r
CA, so it may be easier for clients to connect to Elasticsearch if you use a\r
CSR and send that request to the team that controls your CA.\r
\r
If you choose not to generate a CSR, this tool will generate a new certificate\r
for you. That certificate will be signed by a CA under your control. This is a\r
quick and easy way to secure your cluster with TLS, but you will need to\r
configure all your clients to trust that custom CA.\r
\r
Generate a CSR? \[y/N\]"
send -- "N\r"
expect -exact "N\r
\r
## Do you have an existing Certificate Authority (CA) key-pair that you wish to use to sign your certificate?\r
\r
If you have an existing CA certificate and key, then you can use that CA to\r
sign your new http certificate. This allows you to use the same CA across\r
multiple Elasticsearch clusters which can make it easier to configure clients,\r
and may be easier for you to manage.\r
\r
If you do not have an existing CA, one will be generated for you.\r
\r
Use an existing CA? \[y/N\]"
send -- "N\r"
expect -exact "N\r
A new Certificate Authority will be generated for you\r
\r
## CA Generation Options\r
\r
The generated certificate authority will have the following configuration values.\r
These values have been selected based on secure defaults.\r
You should not need to change these values unless you have specific requirements.\r
\r
Subject DN: CN=Elasticsearch HTTP CA\r
Validity: 5y\r
Key Size: 2048\r
\r
Do you wish to change any of these options? \[y/N\]"
send -- "N\r"
expect -exact "N\r
\r
## CA password\r
\r
We recommend that you protect your CA private key with a strong password.\r
If your key does not have a password (or the password can be easily guessed)\r
then anyone who gets a copy of the key file will be able to generate new certificates\r
and impersonate your Elasticsearch cluster.\r
\r
IT IS IMPORTANT THAT YOU REMEMBER THIS PASSWORD AND KEEP IT SECURE\r
\r
CA password:  \[<ENTER> for none\]"
send -- "\r"
expect -exact "\r
\r
## How long should your certificates be valid?\r
\r
Every certificate has an expiry date. When the expiry date is reached clients\r
will stop trusting your certificate and TLS connections will fail.\r
\r
Best practice suggests that you should either:\r
(a) set this to a short duration (90 - 120 days) and have automatic processes\r
to generate a new certificate before the old one expires, or\r
(b) set it to a longer duration (3 - 5 years) and then perform a manual update\r
a few months before it expires.\r
\r
You may enter the validity period in years (e.g. 3Y), months (e.g. 18M), or days (e.g. 90D)\r
\r
For how long should your certificate be valid? \[5y\] "
send -- "\r"
expect -exact "\r
\r
## Do you wish to generate one certificate per node?\r
\r
If you have multiple nodes in your cluster, then you may choose to generate a\r
separate certificate for each of these nodes. Each certificate will have its\r
own private key, and will be issued for a specific hostname or IP address.\r
\r
Alternatively, you may wish to generate a single certificate that is valid\r
across all the hostnames or addresses in your cluster.\r
\r
If all of your nodes will be accessed through a single domain\r
(e.g. node01.es.example.com, node02.es.example.com, etc) then you may find it\r
simpler to generate one certificate with a wildcard hostname (*.es.example.com)\r
and use that across all of your nodes.\r
\r
However, if you do not have a common domain name, and you expect to add\r
additional nodes to your cluster in the future, then you should generate a\r
certificate per node so that you can more easily generate new certificates when\r
you provision new nodes.\r
\r
Generate a certificate per node? \[y/N\]"
send -- "N\r"
expect -exact "N\r
\r
## Which hostnames will be used to connect to your nodes?\r
\r
These hostnames will be added as \"DNS\" names in the \"Subject Alternative Name\"\r
(SAN) field in your certificate.\r
\r
You should list every hostname and variant that people will use to connect to\r
your cluster over http.\r
Do not list IP addresses here, you will be asked to enter them later.\r
\r
If you wish to use a wildcard certificate (for example *.es.example.com) you\r
can enter that here.\r
\r
Enter all the hostnames that you need, one per line.\r
When you are done, press <ENTER> once more to move on to the next step.\r
\r
"
send -- "*.aserracorp.com\r"
expect -exact "*.aserracorp.com\r
"
send -- "\r"
expect -exact "\r
You entered the following hostnames.\r
\r
 - *.aserracorp.com\r
\r
Is this correct \[Y/n\]"
send -- "Y\r"
expect -exact "Y\r
\r
## Which IP addresses will be used to connect to your nodes?\r
\r
If your clients will ever connect to your nodes by numeric IP address, then you\r
can list these as valid IP \"Subject Alternative Name\" (SAN) fields in your\r
certificate.\r
\r
If you do not have fixed IP addresses, or not wish to support direct IP access\r
to your cluster then you can just press <ENTER> to skip this step.\r
\r
Enter all the IP addresses that you need, one per line.\r
When you are done, press <ENTER> once more to move on to the next step.\r
\r
"
send -- "127.0.0.1\r"
expect -exact "127.0.0.1\r
"
send -- "10.2.1.125\r"
expect -exact "10.2.1.125\r
"
send -- "\r"
expect -exact "\r
You entered the following IP addresses.\r
\r
 - 127.0.0.1\r
 - 10.2.1.125\r
\r
Is this correct \[Y/n\]"
send -- "Y\r"
expect -exact "Y\r
\r
## Other certificate options\r
\r
The generated certificate will have the following additional configuration\r
values. These values have been selected based on a combination of the\r
information you have provided above and secure defaults. You should not need to\r
change these values unless you have specific requirements.\r
\r
Key Name: aserracorp.com\r
Subject DN: CN=aserracorp, DC=com\r
Key Size: 2048\r
\r
Do you wish to change any of these options? \[y/N\]"
send -- "N\r"
expect -exact "N\r
\r
## What password do you want for your private key(s)?\r
\r
Your private key(s) will be stored in a PKCS#12 keystore file named \"http.p12\".\r
This type of keystore is always password protected, but it is possible to use a\r
blank password.\r
\r
If you wish to use a blank password, simply press <enter> at the prompt below.\r
Provide a password for the \"http.p12\" file:  \[<ENTER> for none\]"
send -- "\r"
expect -exact "\r
\r
## Where should we save the generated files?\r
\r
A number of files will be generated including your private key(s),\r
public certificate(s), and sample configuration options for Elastic Stack products.\r
\r
These files will be included in a single zip archive.\r
\r
What filename should be used for the output zip file? \[/usr/share/elasticsearch/elasticsearch-ssl-http.zip\] "
send -- "\r"
expect eof
EOF
sudo chmod +x ./http && sudo ./http && sleep 10 &&  sudo unzip /usr/share/elasticsearch/elasticsearch-ssl-http.zip && sleep 10 && sudo cp kibana/elasticsearch-ca.pem /etc/kibana && cp kibana/elasticsearch-ca.pem /etc/logstash && sudo cp elasticsearch/http.p12 /etc/elasticsearch && sudo cp /usr/share/elasticsearch/elastic-stack-ca.p12 /etc/elasticsearch && sudo cp /usr/share/elasticsearch/elastic-certificates.p12 /etc/elasticsearch && sudo systemctl stop elasticsearch

sudo cat << EOF > elasticsearch2.yml
  # ======================== Elasticsearch Configuration =========================
  path.data: /var/lib/elasticsearch
  path.logs: /var/log/elasticsearch
  xpack.security.enabled: true
  discovery.type: single-node
  xpack.security.http.ssl.enabled: true
  xpack.security.http.ssl.keystore.path: "http.p12"
EOF

sudo cat << EOF > kibana.yml
  # ======================== Kibana Configuration =========================
  elasticsearch.username: kibana_system
  elasticsearch.password: F5demonet!
  elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/elasticsearch-ca.pem"]
  elasticsearch.hosts: ["https://127.0.0.1:9200"]
  xpack.encryptedSavedObjects.encryptionKey: awsedrf545fktghwe324dftygh98ujyhr

EOF
sudo cp kibana.yml /etc/kibana/kibana.yml && sudo rm /etc/elasticsearch/elasticsearch.yml && sudo cp elasticsearch2.yml /etc/elasticsearch/elasticsearch.yml  && sudo systemctl start elasticsearch && sudo systemctl start kibana && sudo systemctl restart nginx && sudo systemctl start logstash

}

setup_passwords
setup_ca
setup_cert
setup_http