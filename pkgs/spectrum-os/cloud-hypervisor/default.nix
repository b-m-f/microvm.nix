{ lib, stdenv, fetchFromGitHub, rustPlatform, pkg-config, dtc, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "cloud-hypervisor";
  version = "34.0";

  src = fetchFromGitHub {
    owner = "cloud-hypervisor";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-+uicO6tPLzwlA4/Fao2J8n82Qnt3C6OfqRxn1pVh7XE=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "acpi_tables-0.1.0" = "sha256-OdtnF2fV6oun3NeCkXdaGU3U7ViBcgFKqHKdyZsRsPA=";
      "kvm-bindings-0.6.0" = "sha256-wGdAuPwsgRIqx9dh0m+hC9A/Akz9qg9BM+p06Fi5ACM=";
      "kvm-ioctls-0.13.0" = "sha256-jHnFGwBWnAa2lRu4a5eRNy1Y26NX5MV8alJ86VR++QE=";
      "micro_http-0.1.0" = "sha256-w2witqKXE60P01oQleujmHSnzMKxynUGKWyq5GEh1Ew=";
      "mshv-bindings-0.1.1" = "sha256-9Q7IXznZ+qdf/d4gO7qVEjbNUUygQDNYLNxz2BECLHc=";
      "versionize_derive-0.1.4" = "sha256-oGuREJ5+FDs8ihmv99WmjIPpL2oPdOr4REk6+7cV/7o=";
      "vfio-bindings-0.4.0" = "sha256-8zdpLD9e1TAwG+m6ifS7/Fh39fAs5VxtnS5gUj/eKmY=";
      "vfio_user-0.1.0" = "sha256-b/gL6vPMW44O44lBIjqS+hgqVUUskBmttGk5UKIMgZk=";
      "vm-fdt-0.2.0" = "sha256-lKW4ZUraHomSDyxgNlD5qTaBTZqM0Fwhhh/08yhrjyE=";
    };
  };

  separateDebugInfo = true;

  vhost = fetchFromGitHub {
    name = "vhost";
    owner = "rust-vmm";
    repo = "vhost";
    rev = "bdc6f2ab2b3dbd3b9574100ac641a2f8e9667400";
    hash = "sha256-p58Jty+GpRFOO9+YcAnDtAAOYi19+7I6FgvnHZZTj0w=";
  };

  postUnpack = ''
    unpackFile ${vhost}
    chmod -R +w vhost
  '';

  cargoPatches = [
    ./0001-build-use-local-vhost.patch
    ./0002-virtio-devices-add-a-GPU-device.patch
  ];

  vhostPatches = [
    vhost/0001-vhost_user-add-shared-memory-region-support.patch
    vhost/0002-devices-vhost-user-add-protocol-flag-for-shmem.patch
  ];

  postPatch = ''
    pushd ../vhost
    for patch in $vhostPatches; do
        echo applying patch $patch
        patch -p1 < $patch
    done
    popd
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ] ++ lib.optional stdenv.isAarch64 dtc;

  OPENSSL_NO_VENDOR = true;

  cargoTestFlags = [
    "--workspace"
    "--bins" "--lib" # Integration tests require root.
    "--exclude" "net_util" # /dev/net/tun
    "--exclude" "vmm"      # /dev/kvm
  ];

  meta = with lib; {
    homepage = "https://github.com/cloud-hypervisor/cloud-hypervisor";
    description = "Open source Virtual Machine Monitor (VMM) that runs on top of KVM";
    changelog = "https://github.com/cloud-hypervisor/cloud-hypervisor/releases/tag/v${version}";
    license = with licenses; [ asl20 bsd3 ];
    maintainers = with maintainers; [ offline qyliss ];
    platforms = [ "aarch64-linux" "x86_64-linux" ];
  };
}
