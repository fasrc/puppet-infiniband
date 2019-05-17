# Fact: infiniband_netdevs
#
# Purpose: Report the network device names and information
#
# Resolution:
#   Returns a hash of netdevice names (ib0) with a hash of data about the device
#
# Caveats:
#   Only tested on systems with Mellanox cards
#

require 'facter/util/infiniband'

Facter.add(:infiniband_netdevs) do
  confine :has_infiniband => true
  setcode do
    Facter::Util::Infiniband.get_netdev_to_hcaport
  end
end
