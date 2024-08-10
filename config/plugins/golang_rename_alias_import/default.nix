{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "golang_rename_alias_import";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-NGJp3a0XWG8P3GTX1LXXAt4zTvBm0UdVf62nmnSFQ2k=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname} $out/bin/${pname}
    cp plugin/golang_rename_alias_import.lua $out/plugin/golang_rename_alias_import.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
