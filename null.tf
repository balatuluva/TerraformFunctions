resource "null_resource" "cluster" {
  count = "${var.environment == "Prod" ? 3 : 1}"
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
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /tmp/userdata.sh",
      "sudo /tmp/userdata.sh",
      "sudo apt update",
      "sudo apt install jq unzip -y",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("SecOps-Key.pem")
      host = element(aws_instance.public-server.*.public_ip, count.index)
    }
  }
}