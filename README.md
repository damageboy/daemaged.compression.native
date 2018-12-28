| Build | Official NuGet | CI Nuget
--------|----------------|---------
| [![Build Status](https://dev.azure.com/damageboy/daemaged.compression.native/_apis/build/status/damageboy.daemaged.compression.native?branchName=master)](https://dev.azure.com/damageboy/daemaged.compression.native/_build/latest?definitionId=1?branchName=master) | | [![Daemaged.Compression.Native package in daemaged feed in Azure Artifacts](https://feeds.dev.azure.com/damageboy/_apis/public/Packaging/Feeds/731945cc-f879-47a4-b66f-5a012b7244e0/Packages/ee3354ee-26ef-4eff-8bd2-eaafe2e07ceb/Badge)](https://dev.azure.com/damageboy/daemaged.compression.native/_packaging?_a=package&feed=731945cc-f879-47a4-b66f-5a012b7244e0&package=ee3354ee-26ef-4eff-8bd2-eaafe2e07ceb&preferRelease=true)

# daemaged.compression.native

An amalgamation of:
* zlib (zlib-ng)
* bzip
* liblzma
* lzo2
* lz4 
* zstd
native compression libs into one .NET Wrapper for .NET Core

This repo holds refs to the various compression libraries unser the src folder, and the azure devops pipeline tha
spins up docker images to build these libraries for the following OS / .NET RIDs:
* ubuntu.14.04
* ubuntu.16.04
* ubuntu.18.04
* debian.9
* rhel.7

and package the entire output under the Daemaged.Compression.Native nuget package.

Users should **not** consume this library directly, but should rather use the Daemaged.Compression library, that has a
dependency on nuget produced by these repo.
