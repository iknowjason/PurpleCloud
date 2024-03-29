###################### Winlogbeat Configuration Example #########################
# Winlogbeat 6, 7, and 8 are currently supported!
# You can download the latest stable version of winlogbeat here:
# https://www.elastic.co/downloads/beats/winlogbeat

# For simplicity/brevity we have only enabled the options necessary for sending windows logs to HELK.
# Please visit the Elastic documentation for the complete details of each option and full reference config:
# https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-reference-yml.html

#-------------------------- Windows Logs To Collect -----------------------------
winlogbeat.event_logs:
  - name: Application
    ignore_older: 30m
  - name: Security
    ignore_older: 30m
  - name: System
    ignore_older: 30m
  - name: Microsoft-windows-sysmon/operational
    ignore_older: 30m
  - name: Microsoft-windows-PowerShell/Operational
    ignore_older: 30m
    event_id: 4103, 4104
  - name: Windows PowerShell
    event_id: 400,600
    ignore_older: 30m
  - name: Microsoft-Windows-WMI-Activity/Operational
    event_id: 5857,5858,5859,5860,5861

#----------------------------- Kafka output --------------------------------
output.kafka:
  # initial brokers for reading cluster metadata
  # Place your HELK IP(s) here (keep the port).
  # Custom configuration for PurpleCloud HELK Server 
  hosts: ["${helk_ip}:9092"]
  topic: "winlogbeat"
  ############################# HELK Optimizing Latency ######################
  max_retries: 2
  max_message_bytes: 1000000
