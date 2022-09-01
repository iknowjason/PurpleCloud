[linux_servers]
${ip}

[linux_servers:vars]
ansible_user=${huser}
ansible_connection=ssh
host_key_checking=No
ansible_host_key_checking=No
ansible_ssh_host_key_checking=No
ansible_python_interpreter=/usr/bin/python3
