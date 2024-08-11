{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "golang_validator_plugin_nvim";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-iXksfx4VlVfX+Q8/A3lqWgcltcaW8oHaQxsYM9kfTmo=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname} $out/bin/${pname}
    cp plugin/hello.lua $out/plugin/hello.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
