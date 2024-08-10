{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "go_import_plugin";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-/Bl4G5STa5lnNntZnMmt+BfES+N7ZYAwC9tzpuqUKcc=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname} $out/bin/${pname}
    cp plugin/go_import_plugin.lua $out/plugin/go_import_plugin.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
