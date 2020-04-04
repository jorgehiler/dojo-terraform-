provider "aws" {
	region = "us-east-2"
}


resource "aws_instance" "example" {
	ami = "ami-0e01ce4ee18447327"
	instance_type = "t2.micro"

    tags = {
        Name = "terraform-jorgehiler"
    }
}
