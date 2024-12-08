resource "null_resource" "cluster" {
  provisioner "file" {
    source = "userdata.sh"
    destination = "/tmp/userdata.sh"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("SecOps-Key.pem")
      host = element(aws_instance.public-server.*.public_ip, count.index)
    }
  }
}