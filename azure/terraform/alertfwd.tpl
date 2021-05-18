#!/bin/bash
sudo apt update && curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt-get -y install nodejs
sudo cat << EOF > /home/afuser/alertforwarder.js
const express = require( 'express' );
const app = express();
const bodyParser = require('body-parser');
const https = require('https')
const http = require('http');
const token = "${github_token}" //Required to authenticate with Github action repo
const repoPath  = '/repos/f5devcentral/adc_performance_monitoring_scaling/dispatches'  //Modify to match designated github action repo
 
 /*  
 Create Listening server - receive alerts from analytics provider
 */

 http.createServer((request, response) => {
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
        esponse.end();
      };

     if (source == "azureLogs"){
      analytic = "azure"
      vals = bodyJson.SearchResults.tables[0].rows[0].toString();
      var hostIndex = vals.search("bigip.azure")
      hostName = vals.substring(hostIndex, hostIndex + 20)


    } else if (source == 'elk') {
      analytic = "elk"
      message = bodyJson.message
      var hostIndex = message.search("bigip.azure")
      hostName = message.substring(hostIndex, hostIndex + 20)
      poolName = ""
    }
    
     //Convert hostName and poolName to arrays and derive identifiers
     var n = hostName.split(".");
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
        event_type: "scale-azure", //+ analytic,
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
      console.log(`Post to Github returned status code`)
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
      response.end();
    }

  // Start listener
  console.log("Starting alert processor...\n")
  }).listen(8000);
EOF
cd /home/afuser && npm install request && npm install express && npm install body-parser && npm install http && npm install https && sudo chmod +x /home/afuser/alertforwarder.js

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



