#cloud-config
manage_etc_hosts: true
preserve_hostname: false

package_upgrade: true

write_files:
  - path: ${bootstrap_dir}/final.sh
    encoding: base64
    content: |
      ${custom_script}
  - path: /etc/nomad.d/nomad.hcl
    encoding: base64
    content: |
      ${nomad_config}
  - path: ${bootstrap_dir}/nomad.sh
    encoding: base64
    content: |
      ${nomad_install}

runcmd:
  - hostnamectl set-hostname ${hostname}-$(curl -s http://169.254.169.254/latest/meta-data/instance-id | tail -c 4)
  - cd ${bootstrap_dir}
  - export ${params}
  - for f in $( ls ${bootstrap_dir}/*/*.sh ) ; do sh $f; done
  - sh ${bootstrap_dir}/nomad.sh
  - systemctl start nomad
  - sh ${bootstrap_dir}/final.sh

output : { all : '| tee -a /var/log/cloud-init-output.log' }