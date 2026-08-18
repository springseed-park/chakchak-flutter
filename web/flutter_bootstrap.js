{{flutter_js}}
{{flutter_build_config}}

// Do not register Flutter's deprecated service worker for the local prototype.
// It otherwise keeps serving a previous UI build after refresh.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath = `${build.mainJsPath}?v=${Date.now()}`;
  }
}
_flutter.loader.load();
