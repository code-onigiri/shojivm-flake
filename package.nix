{
  lib,
  fetchFromGitHub,
  fetchNpmDeps,
  rustPlatform,
  nodejs,
  npmHooks,
  pkg-config,
  wayland-scanner,
  clang,
  libxkbcommon,
  libGL,
  libdrm,
  udev,
  mesa,
  pipewire,
  libgbm,
  wayland,
  wayland-protocols,
  libinput,
  seatd,
  pixman,
  fontconfig,
  freetype,
  xorg,
  version ? "0.1.0",
}:

let
  src = fetchFromGitHub {
    owner = "bea4dev";
    repo = "ShojiWM";
    rev = "main";
    sha256 = "sha256-US5Qn6X5GF2m7ITDw4gOZ223oRmek4+s4wNjNWcrfLQ=";
  };
in

rustPlatform.buildRustPackage {
  pname = "shojiwm";
  inherit version src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "smithay-0.7.0" = "sha256-g5dlLCXhqedqFBi8JcY3mCVkGafLst9pNpFp4mPgffo=";
      "smithay-drm-extras-0.1.0" = "sha256-g5dlLCXhqedqFBi8JcY3mCVkGafLst9pNpFp4mPgffo=";
    };
  };

  cargoBuildFlags = [ "-p" "shoji_wm" "-p" "xdg-desktop-portal-shojiwm" ];

  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    clang
    nodejs
    npmHooks.npmConfigHook
  ];

  buildInputs = [
    libxkbcommon
    libGL
    libdrm
    udev
    mesa
    pipewire
    libgbm
    wayland
    wayland-protocols
    libinput
    seatd
    pixman
    fontconfig
    freetype
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilerrors
    xorg.xcbutilcursor
  ];

  LIBCLANG_PATH = "${clang.cc.lib}/lib";

  npmDeps = fetchNpmDeps {
    src = src;
    source = src;
    name = "shojiwm-npm-deps-${version}";
    hash = "sha256-FFyvtOiLBlufFsHF0wENj0xRkzEyTafaBzKJZWFXmqg=";
  };

  npmRoot = "runtime";

  prePatch = ''
    mkdir -p runtime/packages runtime/tools
    cp package.json package-lock.json tsconfig.json runtime/
    cp -a packages/shoji_wm runtime/packages/
    cp -a packages/config runtime/packages/
    cp tools/decoration-runtime.ts tools/evaluate-decoration.ts runtime/tools/
  '';

  dontCargoInstall = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 target/*/release/shoji_wm $out/bin/shoji_wm
    install -Dm755 target/*/release/xdg-desktop-portal-shojiwm $out/bin/xdg-desktop-portal-shojiwm

    mkdir -p $out/lib/shojiwm
    cp -aL runtime/node_modules $out/lib/shojiwm/node_modules
    cp runtime/package.json runtime/package-lock.json runtime/tsconfig.json $out/lib/shojiwm/
    mkdir -p $out/lib/shojiwm/packages
    cp -aL runtime/packages/shoji_wm $out/lib/shojiwm/packages/
    cp -aL runtime/packages/config $out/lib/shojiwm/packages/
    cp -aL runtime/tools $out/lib/shojiwm/tools
    ln -s $out/lib/shojiwm/packages/shoji_wm $out/lib/shojiwm/node_modules/shoji_wm

    mkdir -p $out/share/shojiwm/default-config
    cp -aL packages/config/* $out/share/shojiwm/default-config/
    rm -rf $out/share/shojiwm/default-config/node_modules 2>/dev/null || true

    install -Dm644 dist/shojiwm.desktop $out/share/wayland-sessions/shojiwm.desktop
    substituteInPlace $out/share/wayland-sessions/shojiwm.desktop \
      --replace-fail '/usr/bin/shoji_wm' 'shoji_wm'

    install -Dm644 dist/shojiwm.portal $out/share/xdg-desktop-portal/portals/shojiwm.portal

    install -Dm644 dist/org.freedesktop.impl.portal.desktop.shojiwm.service \
      $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.shojiwm.service
    substituteInPlace $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.shojiwm.service \
      --replace-fail '/usr/bin/xdg-desktop-portal-shojiwm' '${placeholder "out"}/bin/xdg-desktop-portal-shojiwm'

    install -Dm644 dist/xdg-desktop-portal-shojiwm.service \
      $out/lib/systemd/user/xdg-desktop-portal-shojiwm.service
    substituteInPlace $out/lib/systemd/user/xdg-desktop-portal-shojiwm.service \
      --replace-fail '/usr/bin/xdg-desktop-portal-shojiwm' '${placeholder "out"}/bin/xdg-desktop-portal-shojiwm'

    runHook postInstall
  '';

  meta = with lib; {
    description = "The most customizable Wayland compositor with TypeScript/TSX";
    homepage = "https://github.com/bea4dev/ShojiWM";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "shoji_wm";
  };
}
