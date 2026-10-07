variable "name" {
  type = string
}

variable "random_suffix" {
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

variable "nlb_listener_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
