terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.0.0"
    }
  }

  required_version = "> 0.14"
}

# Locals
locals {
  path_mode = {
    "native" : "native",
    "access" : "untagged",
    "trunk" : "regular"
  }
}

# Data Sources
data "aci_vmm_domain" "vmm" {
  provider_profile_dn = "uni/vmmp-VMware"
  name                = "vmm_vds"
}

data "aci_physical_domain" "phys" {
  name = "prod_physdom"
}

data "aci_l3_outside" "wan" {
  tenant_dn = var.tenant_dn
  name      = "core_l3out"
}

data "aci_contract" "wan" {
  tenant_dn = var.tenant_dn
  name      = "internal_to_wan"
}

# Bridge Domain
resource "aci_bridge_domain" "bd" {
  tenant_dn                 = var.tenant_dn
  name                      = var.name
  arp_flood                 = "yes"
  unicast_route             = var.type == "L3" ? "yes" : "no"
  unk_mac_ucast_act         = var.type == "L3" ? "proxy" : "flood"
  unk_mcast_act             = "flood"
  limit_ip_learn_to_subnets = "yes"

  relation_fv_rs_ctx       = var.vrf_dn
  relation_fv_rs_bd_to_out = var.public ? [data.aci_l3_outside.wan.id] : null
}

resource "aci_subnet" "subnet" {
  count = var.type == "L3" ? 1 : 0

  parent_dn = aci_bridge_domain.bd.id
  ip        = var.subnet
  scope     = var.public ? ["public"] : ["private"]
}

# App Endpoint Groups
resource "aci_application_epg" "epg" {
  name         = var.name
  pref_gr_memb = "include"

  application_profile_dn = "${var.tenant_dn}/app-network"
  relation_fv_rs_bd      = aci_bridge_domain.bd.id

  relation_fv_rs_cons = var.public ? [data.aci_contract.wan.id] : []
}

# App Endpoint Group - VMM Domain Association
resource "aci_epg_to_domain" "vmmdom" {
  application_epg_dn = aci_application_epg.epg.id
  tdn                = data.aci_vmm_domain.vmm.id
}

# App Endpoint Group - Physical Domain Association
resource "aci_epg_to_domain" "physdom" {
  count = length(var.ports) > 0 ? 1 : 0

  application_epg_dn = aci_application_epg.epg.id
  tdn                = data.aci_physical_domain.phys.id
}

# App Endpoint Group - Static Paths (non-vpc)
resource "aci_epg_to_static_path" "path" {
  for_each = {
    for p in var.ports : "${p.pod_id}_${p.leaves_id}_${p.port_id}" => p
    if p.port_type != "vpc"
  }

  application_epg_dn = aci_application_epg.epg.id
  tdn                = "topology/pod-${each.value.pod_id}/paths-${each.value.leaves_id}/pathep-[${each.value.port_id}]"
  encap              = each.value.switchport_type != "native" ? "vlan-${each.value.vlan_id}" : null
  mode               = local.path_mode[each.value.switchport_type]
}

# App Endpoint Group - Static Paths (vpc)
resource "aci_epg_to_static_path" "protpath" {
  for_each = {
    for p in var.ports : "${p.pod_id}_${p.leaves_id}_${p.port_id}" => p
    if p.port_type == "vpc"
  }

  application_epg_dn = aci_application_epg.epg.id
  tdn                = "topology/pod-${each.value.pod_id}/protpaths-${each.value.leaves_id}/pathep-[${each.value.port_id}]"
  encap              = each.value.switchport_type != "native" ? "vlan-${each.value.vlan_id}" : null
  mode               = local.path_mode[each.value.switchport_type]
}
