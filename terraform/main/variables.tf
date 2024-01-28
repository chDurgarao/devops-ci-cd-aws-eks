variable "instance_types" {
  default = {
    "jenkins-master" = "t3.micro"
    "build-slave"    = "t3.micro"
    "ansible"        = "t2.micro"
  }
}