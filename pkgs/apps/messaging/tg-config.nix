{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "tg-config";
  version = "0.1.0";
  format = "pyproject";

  src = ./tg-config;

  nativeBuildInputs = [ python3Packages.hatchling ];
  propagatedBuildInputs = [ python3Packages.cryptography ];

  doCheck = false;

  meta = with lib; {
    description = "Read/write Telegram Desktop tdata settings and apply themes";
    homepage = "https://github.com/meowrch/tg-config";
    license = licenses.mit;
    mainProgram = "tg-config";
    platforms = platforms.linux;
  };
}
