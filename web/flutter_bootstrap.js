// Custom Flutter startup script. `flutter build web` / `flutter run` fill in
// the two {{...}} lines with Flutter's own loader code.
{{flutter_js}}
{{flutter_build_config}}

(function () {
  const loader = document.getElementById('loader');
  const status = document.getElementById('loaderStatus');
  const bar = document.getElementById('loaderBar');

  // Each loading stage moves the top progress bar and updates the text.
  function stage(percent, text) {
    if (bar) bar.style.width = percent + '%';
    if (status && text) status.textContent = text;
  }

  let hidden = false;
  function hideLoader() {
    if (hidden || !loader) return;
    hidden = true;
    stage(100, 'Ready');
    setTimeout(function () {
      loader.classList.add('done');
      setTimeout(function () { loader.remove(); }, 600);
    }, 150);
  }

  stage(20, 'Loading AgosAlert…');

  // Flutter fires this event after drawing the app for the first time.
  window.addEventListener('flutter-first-frame', hideLoader);

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      stage(60, 'Starting up…');
      const appRunner = await engineInitializer.initializeEngine();
      stage(85, 'Almost there…');
      await appRunner.runApp();
      // Safety net in case the first-frame event is missed.
      setTimeout(hideLoader, 1500);
    },
  });
})();
