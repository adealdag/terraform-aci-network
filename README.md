# terraform-aci-network

This module is an example of building a blueprint of ACI infrastructure using Terraform. This module, based on a simplified set of inputs, builds a Bridge Domain and an EPG using what is sometimes called "network-centric" approach.

Module behavior:
* This blueprint uses a 1:1 mapping between BD and EPG. 
* The EPG is automatically deployed on the VMM domain, and can be optinally deployed on a set of statis ports too. 
* The EPG is part of the preferred group, providing open communication within the VRF. 
* If the network is set as `public`, then the module advertises the subnet out of the L3Out to the WAN and sets the appropriate contract to permit communication to the outside.

## Usage

### Example for L3 Network

```hcl
module "prod_net_front_01" {
  source = "github.com/adealdag/terraform-aci-network?ref=v0.1.0"

  name      = "prod_net_front_01"
  tenant_dn = aci_tenant.prod.id
  vrf_dn    = aci_vrf.prod.id

  type   = "L3"
  subnet = "192.168.1.1/24"
  public = true

  ports = [
    {
      pod_id          = "1"
      port_type       = "port"
      leaves_id       = "1101"
      port_id         = "eth1/31"
      vlan_id         = "151"
      switchport_type = "access"
    },
    {
      pod_id          = "1"
      port_type       = "pc"
      leaves_id       = "1101"
      port_id         = "ipg_n7700_l2"
      vlan_id         = "151"
      switchport_type = "trunk"
    },
    {
      pod_id          = "1"
      port_type       = "vpc"
      leaves_id       = "1101-1102"
      port_id         = "ipg_server_001"
      vlan_id         = "151"
      switchport_type = "trunk"
    }
  ]
}
```
