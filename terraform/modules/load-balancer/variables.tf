variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_group_asg_name" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "node_port" {
  type = number
}

variable "health_check_node_port" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
