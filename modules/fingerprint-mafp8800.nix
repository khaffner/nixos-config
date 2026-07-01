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

{ lib, ... }:

let
  # libfprint MR !580 head ("mafp-submission" branch), pinned by commit.
  mafpRev = "776511996f78e2fe6d3a6264cbdf363b32095fcd";
in
{
  # GPD MicroPC 2 fingerprint reader.
  services.fprintd.enable = true;

  # Fingerprint auth for graphical login and sudo (falls back to password).
  # GDM's fingerprint prompt uses the auto-generated `gdm-fingerprint` PAM
  # service, so it needs nothing extra here.
  #
  # NOTE: this makes `sudo` prompt for a finger first. Non-interactive/scripted
  # sudo will wait for the swipe before falling back to the password prompt —
  # flip `sudo.fprintAuth` to false if that gets in the way.
  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
  };

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