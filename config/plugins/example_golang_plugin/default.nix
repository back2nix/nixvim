{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "helloremote";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-4rdEyUWBn7z+939n5NQ9BmC/nI60zZUc2TtPXX3Fuis=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname}  $out/bin/${pname}
    cp plugin/hello.lua $out/plugin/hello.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
