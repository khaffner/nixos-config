# Hardware support module
#
# Common hardware-related settings for Intel-based laptops

{ ... }:

{
  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Firmware update service
  services.fwupd.enable = true;

  # Thermal management for laptops
  services.thermald.enable = true;
}
