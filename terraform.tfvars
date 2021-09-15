project_id = "mylab-324007"
region     = "us-central1"
gke_username = "vijay@mevijay.com"
gke_password = "redhat123"
gke_num_nodes = 1
machineType = "e2-medium"
master_authorized_network_config = {
  cidr_blocks = [
    {
      display_name = "office",
      cidr_block = "100.110.120.130/32"
    }
  ]
