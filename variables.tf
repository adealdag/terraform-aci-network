variable "name" {
  type        = string
  description = "Network name. This value will be used to calculate BD and EPG names"
}

variable "tenant_dn" {
  type        = string
  description = "Distinguised Name (DN) of parent tenant"
}

variable "vrf_dn" {
  type        = string
  description = "Distinguised Name (DN) of parent VRF"
}

variable "anp_dn" {
  type        = string
  description = "Distinguised Name (DN) of parent App Network Profile where the EPG will be deployed"
}

variable "type" {
  type    = string
  default = "L2"
  validation {
    condition     = (var.type == "L2" || var.type == "L3")
    error_message = "Supported values are L2 and L3."
  }
}

variable "subnet" {
  type        = string
  description = "IP address and mask for L3 networks, using the format x.x.x.x/x"
  default     = null
}

variable "public" {
  type        = bool
  default     = false
  description = "Determines if the network has external connectivity or not"
}

# List of static ports
#   port_type allowed values are ["port","pc", "vpc"]
#   leaves_id is either a single leaf (e.g. "1101") or a pair separated by dash (e.g. "1101-1102")
#   port_id is either the policy group name, or interface id (e.g. "eth1/5")
#   vlan_id is the vlan number (e.g. 3120)
#   switchport_type allowed values are ["native",  "access", "trunk"]

variable "ports" {
  type = list(object({
    pod_id          = string
    port_type       = string
    leaves_id       = string
    port_id         = string
    vlan_id         = string
    switchport_type = string
  }))
  description = "List of static ports where the network is deployed"
  default     = []
}
