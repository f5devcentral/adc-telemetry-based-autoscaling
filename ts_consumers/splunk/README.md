Configuring Alerts with Splunk Enterprise
====================================================

**Installing the Splunk Add-on for F5 BIG-IP and Splunk CIM**
-----------------------------------------------------------

Installing the Splunk Add-on for F5 BIG-IP is very simple. I will go over the steps below. In order to make use of the add-on I’ll need to install Splunk’s Common Information Model, (CIM) first and here is how to do that.   

1. From the Splunk Enterprise search page, select ‘Apps’ → ‘Find More Apps’.  

1. Browse for “CIM” and select the Splunk Common Information Model add-on.

1. Accept the license agreement, provide Splunk account login credentials and select ‘Login and Install’.

1. Repeat steps 2-3 to install the Splunk Add-on for F5 BIG-IP. 


**Setup Splunk HTTP Event Collector**
-------------------------------------

To receive incoming telemetry data into my Splunk Enterprise  environment over HTTP/HTTPs, I will need to create an HTTP Event Collector.

1. From the Splunk UI select ‘Settings’ → ‘Data Inputs’. Select ‘HTTP Event Collector’ from the input list.

1. Prior to creating a new event collector token, I must first enable token access for my Splunk environment. On the ‘HTTP Event Collector’ page, select ‘Global Settings’. I set ‘All Tokens’ to enabled, default index, incoming port and ensure SSL is enabled. Click ‘Save’ to exit.

1. Select ‘New Token’ and provide a name for the new collector and select ‘Next’.

1. On the ‘Input Settings’ tab select the necessary allowed index(es) and select ‘Review’ then ‘Submit’.

1. Once the token is created, copy and save the token information so that it can be used when configuring F5 Telemetry streaming.

**Create Splunk Alerts**
--------------------------------------

### Splunk alert query examples

**BIG-IP Scaling**
```
sourcetype="f5:telemetry:json" telemetryEventCategory=AVR MaxCpu>8000 | table hostname |eval source="splunk", scaleAction="scaleOutBigip"
```
```
sourcetype="f5:telemetry:json" telemetryEventCategory=AVR MaxCpu<3000 | table hostname |eval source="splunk", scaleAction="scaleInBigip"
```

**Workload Scaling**
```
sourcetype="f5:telemetry:json" telemetryEventCategory=AVR MaxConcurrentConnections>3000 | table hostname |eval source="splunk", scaleAction="scaleOutWokload"
```
```
sourcetype="f5:telemetry:json" telemetryEventCategory=AVR MaxConcurrentConnections<500 | table hostname |eval source="splunk", scaleAction="scaleInWorkload"
```

<img src="images/splunk.png" alt="Flowers">

<img src="images/splunk1.png" alt="Flowers"  width="700">

<img src="images/splunk3.png" alt="Flowers">