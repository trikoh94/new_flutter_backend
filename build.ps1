# Install Flutter
git clone https://github.com/flutter/flutter.git
$env:Path += ";$PWD\flutter\bin"

# Enable web
flutter config --enable-web

# Get packages and build
flutter pub get
flutter build web 