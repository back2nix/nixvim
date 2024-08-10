{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "golang_rename_import";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-O1anAHCihosdV2R6/gbRl6KrVKPI7fhVYA1q3TFVesw=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname} $out/bin/${pname}
    cp plugin/golang_rename_import.lua $out/plugin/golang_rename_import.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
