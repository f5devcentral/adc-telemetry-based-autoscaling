Configuring Alerts with Elastic Watcher
====================================================
The Elastic ELK stack provides centralized storage, analysis and visualization of organizational data.  Once you have updated the solution to push telemetry data to ELK, (*seleted and renamed appropriate TS configuration file - azure/configs/ts.json, configured the logstash appropriately and modified azure/f5module/autotools.tf*) use the following steps to configure your ELK stack to monitor the log data and send alert triggers to the alertforwarder service when scaling of either the BIG-IP frontend or backend workloads are warranted.


**Create Index Pattern**
-------------------------------------

1. Create an index pattern.  The index pattern will provide a starting base in which to query ingested
   BIG-IP telemetry.  Log into the Kibana GUI portal.  From the upper-left corner select the menu icon and navigate down the sidebar menu to the '*Analytics*'
   section and select '*Discover*', (see below).

   .. image:: ../../images/elk_discover.png

2. From the center panel, select '*Create index pattern*', (see below).

   .. image:: ../../images/index_1.png

3. On the *Create Index Pattern* screen enter ``f5-*`` for the index pattern name.  As the example below illustrates, you should see
   several indexes listed below.  As telemetry data is streamed from the BIG-IP(s) to the ELK stack, (via Logstash - the '*L*' in ELK)
   it is assigned an index with a pattern of **f5-%{+YYYY.MM.dd.hh.mm}**.  Click '*Next Step*' to continue.

   .. image:: ../../images/index_2.png

4. Select **@timestamp** from the drop-down list for the '*Time Field*'.  Select '*Create index pattern*' to complete the process.

   .. image:: ../../../../images/index_3.png


**Create Watcher Alerts**
--------------------------------------

You will be using Elastic Watcher to monitor telemetry data and provide alert notifications.  While still in the *Stack Management*
submenu navigate to and select '*Watcher*', (see above).  From the center panel select '*Create*' and then '*Create threshold alert*'.

   .. image:: ../../images/create_watch.png

For this solution create a total of four (4) alerts.  These alerts will monitor and respond to increases/decreases in BIG-IP CPU
utilization and current application connections.  In the event a member BIG-IP's CPU utilization exceeds or falls below the specified thresholds during the specified interval, an alert will fire triggering a webhook call to the *alertForwarder* service. 
The alertForwarder will subsequently post a BIG-IP scaling request to the central processor, (utilizing the repo's **GitHub Actions**).  
   
Likewise, if current connections fall outside of the specified thresholds a similar alert will be fired.  However, rather than
scaling BIG-IP instances, this will trigger a scaling (up/down) of the backend application workloads, (*solution example: NGINX*).  Use the screenshot example below to create the first alert, (*MaxCpuAlert*).

#. Provide a name, select the previously created index pattern of ``f5-*``, timestamp and timing parameters as shown below. Under
   conditions section select **Max()**, **myMaxCpu**, **top 1**, **hostname.keyword**, **5000** and **5 minutes** as shown below.
   
   **Note:** You should see a green line of the displayed chart that represents the selected field's, (*myMaxCpu*) value trend.  
   This will aid you in setting threshold values appropriately to ensure scaling events are triggered.  With that said, the lab
   environment has been configured with hard limits of (3) BIG-IP instances and (3) workload instances to ensure availability of
   resources for all students.  Additionally, the ADPM processor is designed to throttle requests and prevent superfluous "over-scaling".  Requests that are triggered but not fullfilled, (along with successful requests) are logged on your environment's Consul server.  

   .. image:: ../../images/alert_1.png

#. In the *Actions* section select '*Add action*'.  From the menu pop-up select '*Webhook*', (see below).
   
   .. image:: ../../images/alert_2.png

#. Use the below example to complete the webhook section.  When you are done select '*Create alert*'.  Specifiy ``alertforwarder.f5demo.net`` for the Host. For the webhook body 
   enter ``{"source": "elk", "scaleAction":"scaleOutBigip", "message": "{{ctx.payload}}"}``.  The *alertForwarder* service is expecting the JSON formatted 
   payload and will parse according to source. The *alertForwarder* call the central processer, (via webhook) to trigger scaling.

   .. image:: ../../images/alert_3.png

#. Use the table and example images below to create three additional alerts.  Entries not noted in the table below are identical 
   across alerts.

   .. list-table::
    :widths: 10 10 20 40 20 60 80
    :header-rows: 1
    :stub-columns: 1
    
    * - **Name**
      - **WHEN**
      - **OF**
      - **GROUPED OVER**
      - **IS**
      - **LAST**
      - **Webhook body**
   * - MinCpuAlert
      - max()
      - myCurCons
      - top 1 of hostname.keyword
      - BELOW 1000
      - 5 minutes
      - ``{"source": "elk", "scaleAction":"scaleInBigip", "message": "{{ctx.payload}}"}``
   * - MinConnsAlert
      - max()
      - myCurCons
      - top 1 of hostname.keyword
      - BELOW 50
      - 5 minutes
      - ``{"source": "elk", "scaleAction":"scaleInWorkload", "message": "{{ctx.payload}}"}``
    * - MaxConnsAlert
      - max()
      - myCurCons
      - top 1 of hostname.keyword
      - ABOVE 500
      - 5 minutes
      - ``{"source": "elk", "scaleAction":"scaleOutWorkload", "message": "{{ctx.payload}}"}``

   .. image:: ../../images/alerts.png

Below is an example of a completed Watcher screen.  TS logs are streamed in 60-second intervals.  Depending upon how you set
your thresholds, you may already have alerts firing. The Watcher screen provides one way to monitor alert events.

   .. image:: ../../images/alert_final.png

