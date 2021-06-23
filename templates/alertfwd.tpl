#!/bin/bash
sudo apt update && curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt-get -y install nodejs
sudo cat << EOF > /home/afuser/alertforwarder.js

const express = require( 'express' );
const app = express();
const fs = require('fs');
const bodyParser = require('body-parser');
const https = require('https');
const http = require('http');
const token = "${github_token}" //Required to authenticate with Github action repo
const repoPath  = '${repo_path}'  //Modify to match designated github action repo

 /*  
 Create Listening server - receive alerts from analytics provider
 */
 const options1 = {
  cert: "-----BEGIN CERTIFICATE-----\nMIIFWjCCBEKgAwIBAgITfQAAAB0gY6x6LLG8KwAAAAAAHTANBgkqhkiG9w0BAQUF\nADBOMRMwEQYKCZImiZPyLGQBGRYDY29tMRowGAYKCZImiZPyLGQBGRYKYXNlcnJh\nY29ycDEbMBkGA1UEAxMSYXNlcnJhY29ycC1EQy1DQS0xMB4XDTIwMDIxNTIyMTIw\nMloXDTIyMDIxNDIyMTIwMlowHzEdMBsGA1UEAxMUbXlhcHAuYXNlcnJhY29ycC5j\nb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTGBNbVYLJiIDfL0FQ\nMi/mFzcLeQhP11c4YdxjMBPJKSBWKnXuxywcOJHJ6A2rpGKhAApSsVc6j6sXfCty\nbszbNgvx7KdV8c2S02ILNqlJwTOXRkQhN0srlATYdF/i6T1Y1fpkjBiZMC7A8fRf\nQNwT8DgberiuN4YvfsNGbQej+a1dOVQAGaBn15xwXe8Xfw9iLRangb8n4yAz4qS2\nIJig2UYzSc3P6k1ulZ6I1Yo/xOj7zar3R/09DZ6ikGBvy3TrSfYpRX8pXFgFsJOl\nDeYwzAKlKY4MnapgwszIFMmxveK/d3K+l3Kn0791VdBklrrlycV7itGXrqNYdHLg\nC3dPAgMBAAGjggJeMIICWjA7BgkrBgEEAYI3FQcELjAsBiQrBgEEAYI3FQiBg9Bp\ng5vnB4b5lxighjeD8YE0eYL+ujyChWkCAWQCAQMwEwYDVR0lBAwwCgYIKwYBBQUH\nAwEwDgYDVR0PAQH/BAQDAgWgMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwEw\nHQYDVR0OBBYEFMXq6/mUs8bg5TUoL3uXPUyyAFyXMB8GA1UdIwQYMBaAFBEzMhC4\nl6myjmO0WBY2s0tLj1fQMIHOBgNVHR8EgcYwgcMwgcCggb2ggbqGgbdsZGFwOi8v\nL0NOPWFzZXJyYWNvcnAtREMtQ0EtMSxDTj1kYyxDTj1DRFAsQ049UHVibGljJTIw\nS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1h\nc2VycmFjb3JwLERDPWNvbT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/\nb2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgccGCCsGAQUFBwEBBIG6\nMIG3MIG0BggrBgEFBQcwAoaBp2xkYXA6Ly8vQ049YXNlcnJhY29ycC1EQy1DQS0x\nLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxD\nTj1Db25maWd1cmF0aW9uLERDPWFzZXJyYWNvcnAsREM9Y29tP2NBQ2VydGlmaWNh\ndGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MA0GCSqG\nSIb3DQEBBQUAA4IBAQC8xoaBDhn0BGqQ73ROjlvI+5yJs3UUws2D7KCtpzNt2Ksm\ngm52umZoIzofPRXg/RVkt+Ig7Y9+ixaEyAxMFtpDyap1bTNjWsw99LoUZvMo7B9q\nrgOS55h5OeLwc1PM3n43I9H2C3uQ1hYflD3ovzvzrywejCHlHlReovZkYCcrDCa+\nytw7Hob0P1vkXsPtpmk61A7PCLw6DghhczT1f4nAK147FuRl55jz38JFOtqKVlfU\nNH4EaSxciHO2evWDHUddzeAwxHLg77UKPH+MSPXd7jGZx3xqQEtpjMqq5WM09YsL\n1mwOJpk1Xarkb0WB0J10YXqKs6tSxyrfX/FL5MZA\n-----END CERTIFICATE-----",
  key: "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDTGBNbVYLJiIDf\nL0FQMi/mFzcLeQhP11c4YdxjMBPJKSBWKnXuxywcOJHJ6A2rpGKhAApSsVc6j6sX\nfCtybszbNgvx7KdV8c2S02ILNqlJwTOXRkQhN0srlATYdF/i6T1Y1fpkjBiZMC7A\n8fRfQNwT8DgberiuN4YvfsNGbQej+a1dOVQAGaBn15xwXe8Xfw9iLRangb8n4yAz\n4qS2IJig2UYzSc3P6k1ulZ6I1Yo/xOj7zar3R/09DZ6ikGBvy3TrSfYpRX8pXFgF\nsJOlDeYwzAKlKY4MnapgwszIFMmxveK/d3K+l3Kn0791VdBklrrlycV7itGXrqNY\ndHLgC3dPAgMBAAECggEADudNPo6L/FSR3LAGaXYRoaoT7dBuwMxQUR+/opUbYIFx\n0gOPbftL5vYrfNjQVkT13a4WDH6OzQilqLPQkXS3K+bl8v+lVNEMlYgtDOOgEh/8\n13pThxDTUtFRgkK9HlUfSq1Yz06A0hfvxRmQCkWXBCVaoL4KWep7o9DMUqWR+4ad\nXlvzvG2W3fvNE3+ewwf0tR/OYTQOZvkRfm0Ws1s0W85wr6Ec87psbLPPO2yecFcq\n3fJjcZmbaWWG5Thh9479W3rhC3I6rJN+YLgyXoumml5wmmjf8CxocUL3uPt+32u5\nE4OZTLdAIF0+KxH3hYbw3D6DB/LnAZVB+jxmOC4j2QKBgQDm5JVzld5KYUlIt566\nsyQ95JMyw0Oqp1U7WMwI8+RMYnO4NPo6Dzej9LMsVAQFmg5DncElSf3PLC9PfsVe\nCK6FiXPScy/9cAqchJVI3f7CgJiYvrFwoiieVJFYSgh52aWxL/KHnEe4UWk50qmS\n/hCyPdSCHJVw1oh5dIO/QGG+YwKBgQDqDFi8mNrUI/QD+m/2HNT+6PaXUWEfyY94\n/swvn9O+qQYWbU8MCxeucthTJ5p5lYY5FdUeKPGZn0jahgoEV63XnuemNe43tOJA\nDpo1UyWmQoodAOOm9QiEEjOAxx+hEcSfJrEUgGSYVR+GHbap+xuB0BrtCN9qWsdb\nU2d25b4xJQKBgQCV4SAardhkVA6sQ3WoIA2Ql8Xtl89fAcxT/+pCjX9PDkGr+8fK\n1IH7ziZYyhjqQfysa8UrHYLCbx4u7k3UIrKXQIiMvfUTAR4CSBZX/LMZMzzbOj4Y\nrUrMrHzE4Rnrbxsdj9BRs2LjBQXXYSZuornX2kcORtvDKZ/hp362MWbBnQKBgQCo\nSZZojXQTQ4LKdYGZsmOIotPkO9SdOZ3a/0KsH7zuA7Tn3VMQMs2lVtiq+ff94oCv\nfT5PQFtv/XMyBV0ggDb0qkKgZXjTP1HLg3RoUU/p+0A52JDYVKn55Oh5eTQJ6a+6\nS+TZ+/PZAKP5GFZmZLMDpTInK9ERNRLRXOgxOsKFrQKBgQDH6PfQTuvubwL+CYbb\nCI1AtWOGEGcuLIbtlbh5e4/1FxtdG2pgV2wBJxIwNhn8U7yMHj9B/MB39OAt6Vlc\nZU0Dah41RMi4dPGAi/iuTQklfRLjROSVmhb/lS9xDRxzHcm0u0YBuU0Q+MC3aw7O\njXWs11QDs5AR93mLB0AZdRjGLA==\n-----END PRIVATE KEY-----"

};

 https.createServer(options1, function (request, response) {
  if (request.method == 'POST') {
    
    const { headers, method, url } = request;
    let body = [];
    request.on('error', (err) => {
     console.error(err);
   
      }).on('data', (chunk) => {
      body.push(chunk);
      }).on('end', () => {
     body = Buffer.concat(body).toString();
     bodyJson = JSON.parse(body);
     source = bodyJson.source;
     scaleAction = bodyJson.scaleAction;
     console.log(bodyJson);
      
     if (scaleAction == null){
        console.log("error with scaleaction");
        response.end();
     };

    if (source == "azurelaw"){
        vals = bodyJson.SearchResults.tables[0].rows[0].toString();  
        var hostIndex = vals.search("bigip.azure")
        var hostLength = 20

        if ( hostIndex === "") {
          hostIndex = vals.search("bigip.aws")
          hostLength = 18
        }  
      hostName = vals.substring(hostIndex, hostIndex + hostLength)
    }
      
      
    } else if (source == 'elk' || source == 'splunk' || source == 'default') {
      message = bodyJson.message
      var hostIndex = message.search("bigip.azure")
      var hostLength = 20

      if ( hostIndex === "") {
          hostIndex = message.search("bigip.aws")
          hostlength = 18
      }  
      hostName = message.substring(hostIndex, hostIndex + hostLength)
      
    } else {
      console.log("Invalid nalytics source specified")
      response.end();
    }

     //Convert hostName to arrays and derive identifiers
     var n = hostName.split(".");
     cloud = n[1];
     app_id = n[2];

     //Create scaling eventtype
     var app_name = "app1";
     switch (scaleAction) {
       case "scaleOutBigip":
          what2Scale = 'bigip';
          scaling_direction = 'up'
          app_name = app_name
          break;
      case "scaleInBigip":
          what2Scale = 'bigip';
          scaling_direction = 'down'
          app_name = app_name
          break;
      case "scaleOutWorkload":
          what2Scale = 'app';
          scaling_direction = 'up'
          app_name = app_name
          break;
      case "scaleInWorkload":
          what2Scale = 'app';
          scaling_direction = 'down'
          app_name = app_name
          break;
     } 
    
    console.log("The application ID is " + app_id + ". Webhook request to scale the " + what2Scale + " " + scaling_direction + ".  If relevant, the app name is '" + app_name + "'.")    

    //Construct Github Action webhook payload
    const data2 = JSON.stringify({
        event_type: "scale-" + cloud,
        client_payload: {
            scaling_type: what2Scale,
            app_name: app_name,
            scaling_direction: scaling_direction,
            webhook_source: source,
            app_id: app_id
          }
        })

    const options = {
       hostname: 'api.github.com',
       port: 443,
       path: repoPath,
       method: 'POST',
       headers: {
         'Content-Type': 'application/json',
         'Content-Length': data2.length,
         'Authorization': 'token ' + token,
         'user-agent': 'node.js'
       }
    }
    
    /*
    Create https POST to github
    */
    const req2 = https.request(options, res2 => {
      console.log("Processing operation complete.\n")
     
      res2.on('data', d => {
         process.stdout.write(d)
       })
     })  

     req2.on('error', error => {
       console.error(error)
     })     

     // submit payload via webhook to Github Action
     req2.write(data2)
     req2.end()

     response.on('error', (err) => {
       console.error(err);
     });

     response.writeHead(200, {'Content-Type': 'application/json'})
     const responseBody = { headers, method, url, body };
     response.write(JSON.stringify(responseBody));

     response.end();
     });
    }
    else {
      console.log("Invalid HTTP method");
      response.end();
    }

  // Start listener
  console.log("Starting alert processor...\n");
  }).listen(8000); 
EOF
cd /home/afuser && npm install request && npm install express && npm install body-parser && npm install http && npm install fs && npm install https && sudo chmod +x /home/afuser/alertforwarder.js

sudo cat << EOF > /etc/systemd/system/alertforwarder.service 
[Unit]
Description=alertforwarder
[Service]
ExecStart=/usr/bin/node /home/afuser/alertforwarder.js
Restart=always
User=nobody
# Note Debian/Ubuntu uses 'nogroup', RHEL/Fedora uses 'nobody'
Group=nogroup
Environment=PATH=/usr/bin:/usr/local/bin:/home/afuser
Environment=NODE_ENV=production
WorkingDirectory=/home/afuser

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start alertforwarder.service && sudo systemctl stop alertforwarder.service && sudo systemctl restart alertforwarder.service



