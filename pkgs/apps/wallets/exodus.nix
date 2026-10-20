{
  exodus,
  fetchurl,
}:

exodus.overrideAttrs (old: {
  src = fetchurl {
    url = "https://downloads.exodus.com/releases/exodus-linux-x64-${old.version}.zip";
    hash = "sha256-BClWuL4dTc1lESyEXuDtpGp1K/AxICbpQIaWYLrme1M=";
  };
})
