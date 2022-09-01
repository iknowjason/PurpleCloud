version:
  name: velociraptor
  version: 0.6.6
Client:
  server_urls:
  - https://${helk_ip}:8000/
  ca_certificate: |
    ${ca_crt}
  nonce: dStW1TofRz8=
  writeback_darwin: /etc/velociraptor.writeback.yaml
  writeback_linux: /etc/velociraptor.writeback.yaml
  writeback_windows: $ProgramFiles\Velociraptor\velociraptor.writeback.yaml
  tempdir_windows: $ProgramFiles\Velociraptor\Tools
  max_poll: 60
  windows_installer:
    service_name: Velociraptor
    install_path: $ProgramFiles\Velociraptor\Velociraptor.exe
    service_description: Velociraptor service
  darwin_installer:
    service_name: com.velocidex.velociraptor
    install_path: /usr/local/sbin/velociraptor
  version:
    name: velociraptor
    version: 0.6.6
  use_self_signed_ssl: true
  pinned_server_name: VelociraptorServer
  max_upload_size: 5242880
  local_buffer:
    memory_size: 52428800
    disk_size: 1073741824
    filename_linux: /var/tmp/Velociraptor_Buffer.bin
    filename_windows: $TEMP/Velociraptor_Buffer.bin
    filename_darwin: /var/tmp/Velociraptor_Buffer.bin
API:
  bind_address: ${helk_ip} 
  bind_port: 8001
  bind_scheme: tcp
  pinned_gw_name: GRPC_GW
GUI:
  bind_address: ${helk_ip} 
  bind_port: 8889
  gw_certificate: |
    ${gw_crt}
  gw_private_key: |
    ${gw_key}
  internal_cidr:
  - 127.0.0.1/12
  - 192.168.0.0/16
  authenticator:
    type: Basic
CA:
  private_key: |
    ${ca_key}
Frontend:
  hostname: localhost
  bind_address: 0.0.0.0
  bind_port: 8000
  certificate: |
    ${fe_crt}
  private_key: |
    ${fe_key}
  max_upload_size: 10485760
  dyn_dns: {}
  default_client_monitoring_artifacts:
  - Generic.Client.Stats
  expected_clients: 10000
  GRPC_pool_max_size: 100
  GRPC_pool_max_wait: 60
Datastore:
  implementation: FileBaseDataStore
  location: /var/tmp/velociraptor
  filestore_directory: /var/tmp/velociraptor
Writeback: {}
Mail: {}
Logging: {}
Monitoring:
  bind_address: 10.100.30.4
  bind_port: 8003
api_config: {}
obfuscation_nonce: icPEtWQRLWs=
