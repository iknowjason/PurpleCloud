
Test SSH connection:
ANSIBLE_HOST_KEY_CHECKING=False ansible linux_servers -i hosts.cfg --private-key ssh_key.pem -m ping

Run the Linux ansible playbook:
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.cfg --private-key ssh_key.pem ./playbook.yml
