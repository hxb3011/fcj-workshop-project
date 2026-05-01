variable "function_name" {
  type = string
}

variable "filename" {
  type = string
}

variable "timeout" {
  type    = number
  default = 60
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "additional_policies" {
  type    = list(any)
  default = []
}