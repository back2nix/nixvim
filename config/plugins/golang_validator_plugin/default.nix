{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "golang_validator_plugin";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-d45oRvsuAzKBhFhyQPteb0GhnMO6jn2aZyf2k4X/weA=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname} $out/bin/${pname}
    cp plugin/golang_validator_plugin.lua $out/plugin/golang_validator_plugin.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
