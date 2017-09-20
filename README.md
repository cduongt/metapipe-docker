# metapipe-docker
This is a Dockerfile for [Metapipe deployment tool](https://github.com/cduongt/mmg-cluster-setup-CESNET). It contains necessary tools like Terraform, Ansible and VOMS client for Metapipe deployment.

## How to get:
* Install latest [Docker CE](https://docs.docker.com/engine/installation/#server)
* Either build from scratch (requires git):
	* ``` git clone https://github.com/cduongt/metapipe-docker.git```
	* ``` cd metapipe-docker ``` 
	*	```sudo docker build -t metapipe-docker```
* Or get image from Docker hub:
	* ```sudo docker pull cduongt/metapipe-docker ```

## Prepare credentials and config:
Clone metapipe tool:
 ```git clone https://github.com/cduongt/mmg-cluster-setup-CESNET.git```

Necessary files for usage, copy them to mmg-cluster-setup-CESNET folder:
* ```context```
* ```id_rsa```
* ```mmg_cluster.tf```
* ```usercert.pem``` and ```userkey.pem``` if using fedcloud.egi.eu or other compatible VO with VOMS client
* Or ```elixirx509``` if using ELIXIR VO

### Files
 ```context``` - Contextulisation cloud-init file
 Sample context file:
```
#cloud-config
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock-passwd: true
    ssh-import-id: cloud-user
    ssh-authorized-keys:
      - ssh-rsa
MIIBCgKCAQEA+xGZ/wcz9ugFpP07Nspo6U17l0YhFiFpxxU4pTk3Lifz9R3zsIsuERwta7+fWIfxOo208ett/jhskiVodSEt3QBGh4XBipyWopKwZ93HHaDVZAALi/2A+xTBtWdEo7XGUujKDvC2/aZKukfjpOiUI8AhLAfjmlcD/UZ1QPh0mHsglRNCmpCwmwSXA9VNmhz+PiB+Dml4WWnKW/VHo2ujTXxq7+efMU4H2fny3Se3KYOsFPFGZ1TNQSYlFuShWrHPtiLmUdPoP6CV2mML1tk+l7DIIqXrQhLUKDACeM5roMx0kLhUWB8P+0uj1CNlNN4JRZlC7xFfqiMbFRU9Z4N6YwIDAQAB cloud-user
```
```id_rsa``` - Private key which is paired with public key in context file, must be unlocked (without password)
```mmg-cluster.tf``` - Terraform configuration file
Sample config:
```
resource "occi_virtual_machine" "master" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_fe71524e_66d3_5d09_8375_c5510ed5ccba_warg_default_shared_230"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_master"
	x509 = "/tmp/x509up_u0"
	init_file = "/metapipe-files/mmg-cluster-setup-CESNET/context"
	storage_size = 300
}

resource "occi_virtual_machine" "node" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_fe71524e_66d3_5d09_8375_c5510ed5ccba_warg_default_shared_230"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_node"
	x509 = "/tmp/x509up_u0"
	init_file = "/metapipe-files/mmg-cluster-setup-CESNET/context"
	count = 2
	storage_size = 50
}

output "master_ip" {
	value = "${occi_virtual_machine.master.ip_address}"
}

output "master_id" {
	value = "${occi_virtual_machine.master.id}"
}

output "master_storage_link" {
	value = "${occi_virtual_machine.master.storage_link}"
}

output "node_ip" {
	value = "${join(",",occi_virtual_machine.node.*.ip_address)}"
}

output "node_id" {
	value = "${occi_virtual_machine.node.0.id}"
}

output "master_storage_size" {
	value = "${occi_virtual_machine.master.storage_size}"
}

output "node_storage_size" {
	value = "${occi_virtual_machine.node.0.storage_size}"
}

output "occi_endpoint" {
	value = "${occi_virtual_machine.master.endpoint}"
}

output "proxy_file" {
	value = "${occi_virtual_machine.master.x509}"
}
```
```usercert.pem``` and ```userkey.pem``` - Credential files needed to generate proxy file for accessing EGI resources
```elixirx509``` - Proxy file generated for [ELIXIR VO](https://wiki.egi.eu/wiki/ELIXIR_Virtual_Organisation)

Your directory should look like this:
```
[cduongt@localhost ~]$ tree -L 2 metapipe-docker/
metapipe-docker/
├── Dockerfile
├── mmg-cluster-setup-CESNET
│   ├── context
│   ├── create.py
│   ├── destroy.py
│   ├── id_rsa
│   ├── mmg-cluster.tf
│   ├── pouta-ansible-cluster
│   ├── provision
│   ├── README.md
│   ├── run.py
│   ├── stop.py
│   ├── templates
│   ├── usercert.pem
│   └── userkey.pem
└── README.md

```

## How to use
If you use fedcloud.egi.eu or similar VO, otherwise skip:
```
sudo docker run -v /home/cduongt/metapipe-docker:/metapipe-files -v /tmp:/tmp metapipe-docker voms-proxy-init --voms fedcloud.egi.eu --rfc
```
Creating and provisioning cluster:
```
sudo docker run -v /home/cduongt/metapipe-docker:/metapipe-files -v /tmp:/tmp metapipe-docker ./create.py
```
Starting Metapipe with custom job tag:
```
sudo docker run -v /home/cduongt/metapipe-docker:/metapipe-files -v /tmp:/tmp metapipe-docker ./run.py jobtag
```
Stop metapipe:
```
sudo docker run -v /home/cduongt/metapipe-docker:/metapipe-files -v /tmp:/tmp metapipe-docker ./stop.py
```
Stop metapipe and delete cluster:
```
sudo docker run -v /home/cduongt/metapipe-docker:/metapipe-files -v /tmp:/tmp metapipe-docker ./destroy.py
```

## Common issues:
1) Cluster is created, but provisioning fails - check if ```id_rsa``` file can be used without password - there is currently no way how to pass password to docker input
