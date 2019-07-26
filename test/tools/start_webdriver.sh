#!/usr/bin/env bash

# Lovingly borrowed from
# https://github.com/HashNuke/hound/

if [ "$WALLABY_DRIVER" = "selenium" ]; then
  export DISPLAY=:99.0
  /sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1280x1024x16

  mkdir -p $HOME/bin
  export PATH=$HOME/bin:$PATH

  curl https://selenium-release.storage.googleapis.com/3.14/selenium-server-standalone-3.14.0.jar -o $HOME/selenium.jar
  # Geckodriver requires java 8.
  sudo add-apt-repository -y ppa:openjdk-r/ppa
  sudo apt-get update && sudo apt-get install -y openjdk-8-jdk

  # Install jdk switcher to easily change default jdk
  git clone https://github.com/michaelklishin/jdk_switcher.git $HOME/jdk_switcher
  . $HOME/jdk_switcher/jdk_switcher.sh
  jdk_switcher use openjdk8

  # Download geckodriver
  curl -L https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-linux64.tar.gz -o $HOME/geckodriver.tar.gz
  tar xfz $HOME/geckodriver.tar.gz -C $HOME/bin

  # Download latest firefox
  export FIREFOX_SOURCE_URL='https://download.mozilla.org/?product=firefox-latest&lang=en-US&os=linux64'
  wget -O /tmp/firefox-latest.tar.bz2 $FIREFOX_SOURCE_URL
  mkdir -p $HOME/firefox-latest
  tar xf /tmp/firefox-latest.tar.bz2 -C $HOME/firefox-latest
  export PATH=$HOME/firefox-latest/firefox:$PATH

  java -version

  nohup java -jar $HOME/selenium.jar &
  echo "Running with Selenium"
  sleep 10
  cat nohup.out
fi
