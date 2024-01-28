# resource "aws_key_pair" "keypair" {
#   key_name                    = var.webserver_info.key_name
#   public_key                  = file(var.key_path)
# }

resource "aws_instance" "WebServer" {
  count                         = local.count
  ami                           = data.aws_ami.latest-amazon-linux-image.id
  instance_type                 = local.instance_type
  associate_public_ip_address   = local.public_ip_enabled
  key_name                      = local.key_name 
  subnet_id                     = aws_subnet.pub_subnets[count.index].id
  vpc_security_group_ids        = [aws_security_group.Web-SG.id]

  tags                          = {
      Name                      = local.webserver_tags[count.index]
  }
  depends_on    = [ aws_vpc.vnet, aws_subnet.pub_subnets]


}

resource "null_resource" "webProvisioner" {
  count    = local.count
  triggers = {
    exec_trigger = local.hammer
  }
      
  provisioner "remote-exec" {
  connection {
    type        = local.connection_type
    user        = local.username
    private_key = file(local.key_path)
    host        = aws_instance.WebServer.*.public_ip[count.index]
  }
  inline        = [
    "sudo amazon-linux-extras install nginx1 -y",
    "sudo systemctl start nginx.service",
    "sudo systemctl enable nginx.service",
    "sudo yum install tree -y"
    ]
  }
}

