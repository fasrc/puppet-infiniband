# @summary Manage IPoIB interface
#
# @example Creates the ifcfg file for an IBoIP interface
#   infiniband::interface { 'ib0':
#     ipaddr  => '192.168.1.1',
#     netmask => '255.255.255.0',
#   }
#
#
# @param name
#   The resource title.  Sets the interfaces name, for example 'ib0'.
# @param ipaddr
#   The IPADDR for the infiniband interface.
# @param netmask
#   The NETMASK for the infiniband interface.
# @param gateway
#   The GATEWAY for the infiniband interface.
# @param ensure
#   Sets if the infiniband::interface should be present or absent.
# @param enable
#   Sets if the infiniband::interface should be enabled at boot.
# @param nm_controlled
#   Value for nm_controlled on interface
# @param connected_mode
#   The CONNECTED_MODE value for the infiniband interface.
# @param mtu
#   The MTU for the infiniband interface.
# @param bonding
#   If this interface is a bonding interface (true/false); defaults to false
# @param bonding_slaves
#   Array of interfaces that should be enslaved in the bonding interface
# @param bonding_opts
#   The bonding options to use for this bonding interface
#
define infiniband::interface (
  Optional[Stdlib::IP::Address] $ipaddr                       = undef,
  Optional[Stdlib::IP::Address] $netmask                      = undef ,
  Optional[Stdlib::IP::Address] $gateway                      = undef,
  Enum['present', 'absent'] $ensure                           = 'present',
  Boolean $enable                                             = true,
  Enum['yes', 'no'] $connected_mode                           = 'yes',
  Optional[Variant[Boolean, Enum['yes','no']]] $nm_controlled = undef,
  Optional[Integer] $mtu                                      = undef,
  Boolean $bonding                                            = false,
  Array[String] $bonding_slaves                               = [],
  String $bonding_opts                                        = 'mode=active-backup miimon=100',
) {

  $onboot = $enable ? {
    String  => $enable,
    Boolean => $enable ? {
      true  => 'yes',
      false => 'no',
    },
  }

  $options_extra_redhat = {
    'CONNECTED_MODE' => $connected_mode,
  }

  if $::osfamily == 'RedHat' and versioncmp($::operatingsystemmajrelease, '8') >= 0 {
    $_nm_controlled = pick($nm_controlled, false)
  } else {
    $_nm_controlled = pick($nm_controlled, 'no')
  }

  if $bonding {
    if empty($bonding_slaves) {
      fail("No slave interfaces given for bonding interface ${name}")
    }

    # Setup interfaces for the slaves
    $bonding_slaves.each |String $ifname| {
      network_config { $ifname:
        ensure               => $ensure,
        onboot               => $onboot,
        master               => $name,
        slave                => 'yes',
        mtu                  => $mtu,
        method               => 'static',
        hotplug              => 'false',
        options              => {
          'TYPE'          => 'Infiniband',
          'NM_CONTROLLED' => $_nm_controlled,
        }
      }
    }

    # Setup the bonding interface
    network_config { $name:
      ensure         => $ensure,
      onboot         => $onboot,
      ipaddress      => $ipaddr,
      netmask        => $netmask,
      bonding_master => 'yes',
      bonding_opts   => $bonding_opts,
      mtu            => $mtu,
      method         => 'static',
      hotplug        => 'false',
      options        => {
        'TYPE'          => 'Infiniband',
        'NM_CONTROLLED' => $_nm_controlled,
        'GATEWAY'       => $gateway,
      }
    }

  } else {
    network_config { $name:
      ensure               => $ensure,
      onboot               => $onboot,
      ipaddress            => $ipaddr,
      netmask              => $netmask,
      mtu                  => $mtu,
      method               => 'static',
      hotplug              => 'false',
      options              => {
        'TYPE'          => 'Infiniband',
        'NM_CONTROLLED' => $_nm_controlled,
        'GATEWAY'       => $gateway,
      }
    }
  }

}
