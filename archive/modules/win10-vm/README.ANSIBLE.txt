Test WinRM connection:
$ ansible windows_servers -i hosts.cfg -m win_ping
 

Run an ansible playbook:
$ ansible-playbook -i hosts.cfg playbook.yml


# should look something like this 
$ cat hosts.cfg 
[windows_servers]
40.87.26.161

[windows_servers:vars]
ansible_user=RTCAdmin
ansible_password=Password123
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
