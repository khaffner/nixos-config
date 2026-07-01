# TEMPORARY: fingerprint support for the GPD MicroPC 2 (GPDMICROPC2 host).
#
# The built-in reader is a Microarray MAFP8800 SPI sensor (ACPI HID "MAFP8800").
# There is NO driver for it in released libfprint yet — support is proposed
# upstream, still UNMERGED, in libfprint MR !580:
#   https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/580
#
# This module builds libfprint from that MR's commit via an overlay; fprintd is
# rebuilt against it automatically. nixpkgs already builds libfprint with
# `-Ddrivers=all`, and the MR registers `mafp8800` in the meson driver list, so
# no extra build flags are needed to include the driver.
#
# Once the driver lands in nixpkgs: delete this file, drop the import, rebuild.

{ lib, pkgs, ... }:

let
  # libfprint MR !580 head ("mafp-submission" branch), pinned by commit.
  mafpRev = "776511996f78e2fe6d3a6264cbdf363b32095fcd";
in
{
  # GPD MicroPC 2 fingerprint reader.
  services.fprintd.enable = true;

  # --- Expose the sensor to userspace -----------------------------------------
  # The sensor is an SPI device behind ACPI HID MAFP8800. The kernel enumerates
  # it on the SPI bus but binds no driver, so no /dev/spidev node appears and
  # fprintd reports "No devices available". Force-bind it to spidev via udev,
  # ensure the spidev module is loaded, and raise its buffer size for the
  # driver's ~20 KB SPI transfers.
  boot.kernelModules = [ "spidev" ];

  boot.extraModprobeConfig = ''
    options spidev bufsiz=32768
  '';

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="spi", ENV{MODALIAS}=="acpi:MAFP8800:", RUN{builtin}+="kmod load spi:spidev", RUN+="${pkgs.bash}/bin/sh -c 'echo spidev > %S%p/driver_override && echo %k > %S%p/subsystem/drivers/spidev/bind'"
  '';

  # --- PAM ---------------------------------------------------------------------
  # Graphical login: GDM uses its own auto-generated `gdm-fingerprint` PAM stack
  # (enabled for free by services.fprintd.enable), so nothing to set here.
  # We only opt `sudo` into fingerprint auth; it falls back to password.
  #
  # NOTE: this makes `sudo` prompt for a finger first. Non-interactive/scripted
  # sudo will wait for the swipe before falling back to the password prompt —
  # flip this to false if that gets in the way.
  #
  # (Deliberately NOT setting `login.fprintAuth`: that's the text-console getty
  # login, and the GDM module pins it to false — setting it true conflicts.
  # If you also want fingerprint on a TTY, use `lib.mkForce true` there.)
  security.pam.services.sudo.fprintAuth = true;

  # --- Build libfprint with the mafp8800 driver -------------------------------
  nixpkgs.overlays = [
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (old: {
        src = final.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "libfprint";
          repo = "libfprint";
          rev = mafpRev;
          hash = "sha256-HHh+I83UyFNYp/jFi5ouHx3UUN7woH1wS1Z1BIHhGaA=";
        };

        # This commit runs a Python test-introspection step (unittest_inspector.py)
        # at meson configure time that can't execute in the sandbox. That whole
        # block is gated behind `introspection`, so turn it off. We don't need the
        # FPrint GObject typelib: fprintd links libfprint via pkg-config (C), and
        # its own test suite — the only consumer of the typelib — doesn't run
        # (fprintd sets no doCheck). PAM/GNOME reach fprintd over D-Bus, not GIR.
        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dintrospection=false" ];

        # The MR ships no test fixtures for this driver and version drift can
        # break the in-tree checks; skip them.
        doInstallCheck = false;
      });
    })
  ];
}