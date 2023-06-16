resource "aws_key_pair" "key_tf" {
    key_name = "key_tf"
    public_key = file("${path.module}/keytform.pub")
}
