const express = require( 'express' );
const app = express();
const bodyParser = require('body-parser');
const https = require('https')
const http = require('http');
const args = process.argv.slice(2) //Required to authenticate with Github action repo

const repoPath  = '/repos/gregcoward/adcpm-automationn/dispatches'  //Modify to match designated github action repo
 
 /*  
 Create Listening server - receive alerts from analytics provider
 */

 http.createServer((request, response) => {
   const { headers, method, url } = request;
   let body = [];
   
   request.on('error', (err) => {
     console.error(err);
   
    }).on('data', (chunk) => {
      body.push(chunk);
    }).on('end', () => {
     body = Buffer.concat(body).toString();
     bodyJson = JSON.parse(body);
     scaleAction = bodyJson.scaleAction;
     hostName = bodyJson.SearchResults.tables[0].rows[0].toString();
     
     //Convert hostname to array and derive identifiers from hostname
     var n = hostName.split(".");
     
     //Create scaling eventtyp
     switch (scaleAction) {
       case "scaleOutBigip":
          what2Scale = 'bigip';
          eventType = 'scale-out-' + n[1]
          break;
      case "scaleInBigip":
          what2Scale = 'bigip';
          eventType = 'scale-in-' + n[1]
          break;
      case "scaleOutApp":
          what2Scale = 'app';
          eventType = 'scale-out-' + n[1]   
          break;
      case "scaleInApp":
          what2Scale = 'app';
          eventType = 'scale-in-' + n[1]
          break;
     } 

    //Construct Github Action webhook payload
    const data2 = JSON.stringify({
        event_type: eventType,
        client_payload: {
            cloud: n[1],
            rgGrpRgn: n[2],
            scaleName: n[3],
            what_to_scale: what2Scale,
            bigip_hostname: hostName, 
            bigip_app: '',
            webhook_source: 'azureloganalytics'
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
         'Authorization': 'token ' + args[0],
         'user-agent': 'node.js'
       }
    }
    
    /*
    Create https POST to github
    */
    const req2 = https.request(options, res2 => {
       console.log(`statusCode: ${res2.statusCode}`)
     
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

  // Start listener
  }).listen(8000);
