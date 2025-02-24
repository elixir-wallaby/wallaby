{
  pkgs ? import <nixpkgs> {},
  jre,
  chromedriver,
  geckodriver,
  makeWrapper,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "selenium-server";
  version = "4.27.0";

  src = pkgs.fetchurl {
    # https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.27.0/selenium-server-4.27.0.jar
    url = "https://github.com/SeleniumHQ/selenium/releases/download/selenium-${version}/selenium-server-${version}.jar";
    sha256 = "sha256-VIHKCYFPwOyMK4/we4V0pGf0nwwoUQexUlMl1TVAjWo=";
  };

  dontUnpack = true;

  nativeBuildInputs = [makeWrapper];
  buildInputs = [jre];

  installPhase = ''
    mkdir -p $out/share/lib/${pname}-${version}
    cp $src $out/share/lib/${pname}-${version}/${pname}-${version}.jar
    makeWrapper ${jre}/bin/java $out/bin/selenium-server \
      --add-flags "-Dwebdriver.chrome.driver=${chromedriver}/bin/chromedriver" \
      --add-flags "-Dwebdriver.firefox.driver=${geckodriver}/bin/geckodriver" \
      --add-flags "-jar $out/share/lib/${pname}-${version}/${pname}-${version}.jar"
  '';

  meta.main = "selenium-server";
}
