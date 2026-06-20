{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myModules.nixos.shojiwm;
  shojiwmPkg = cfg.package;
in {
  options.myModules.nixos.shojiwm = {
    enable = mkEnableOption "ShojiWM Wayland compositor";

    package = mkOption {
      type = types.package;
      default = pkgs.shojiwm;
      defaultText = lib.literalExpression "pkgs.shojiwm";
      description = "ShojiWM package to use";
    };

    extraPortalConfig = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Extra xdg-desktop-portal configuration for ShojiWM";
    };

    enablePortal = mkOption {
      type = types.bool;
      default = true;
      description = "Enable xdg-desktop-portal-shojiwm backend";
    };
  };

  config = mkIf cfg.enable {
    # Package + xwayland-satellite
    environment.systemPackages = [ shojiwmPkg pkgs.xwayland-satellite ];

    # Symlink the TS runtime to /usr/lib/shojiwm so the compositor can find it
    systemd.tmpfiles.rules = [
      "L+ /usr/lib/shojiwm - - - - ${shojiwmPkg}/lib/shojiwm"
    ];

    # Wayland session so display managers see ShojiWM
    services.displayManager.sessionPackages = [ shojiwmPkg ];

    # xdg-desktop-portal backend for screen capture
    xdg.portal = mkIf cfg.enablePortal {
      enable = true;
      extraPortals = [ shojiwmPkg ];
      config = mkMerge [
        {
          common.default = [ "gtk" "shojiwm" ];
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
        }
        {
          shojiwm = {
            default = [ "shojiwm" "gtk" ];
          };
        }
        cfg.extraPortalConfig
      ];
    };

    # Session environment variables
    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "ShojiWM";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
