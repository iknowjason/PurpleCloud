[windows_servers]
${ip}

[windows_servers:vars]
ansible_user=${auser}
ansible_password=${apwd}
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
