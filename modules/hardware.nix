# Hardware support module
#
# Common hardware-related settings for Intel-based laptops

{ ... }:

{
  # Load Intel KMS in the initrd so the splash + LUKS prompt render at native resolution before unlock.
  boot.initrd.kernelModules = [ "i915" ];

  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Firmware update service
  services.fwupd.enable = true;

  # Thermal management for laptops
  services.thermald.enable = true;
}
