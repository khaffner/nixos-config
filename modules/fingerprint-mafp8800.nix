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
# no extra build flags are needed.
#
# Once the driver lands in nixpkgs: delete this file, drop the import, rebuild.
#
# ── Filling in the hash ────────────────────────────────────────────────────
# The MR commit's source hash can't be known in advance. Leave `lib.fakeHash`
# below for the first `nixos-rebuild`; it will fail with:
#     error: hash mismatch ... got: sha256-XXXXXXXX...
# Paste that `got:` value into `hash` and rebuild again.

{ lib, ... }:

let
  # libfprint MR !580 head ("mafp-submission" branch), pinned by commit.
  mafpRev = "776511996f78e2fe6d3a6264cbdf363b32095fcd";
in
{
  # GPD MicroPC 2 fingerprint reader.
  services.fprintd.enable = true;

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

        # The MR commit is newer than the pinned release and ships no test
        # fixtures for this driver; skip the in-tree checks to avoid version
        # drift breaking the build.
        doInstallCheck = false;
      });
    })
  ];
}