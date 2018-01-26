# use to create an elastic ip resource, associate with an instance
resource "aws_eip" "eip" {
  instance = "${var.instance_id}"
  vpc      = true
  }

