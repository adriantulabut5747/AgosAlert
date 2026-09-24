// Custom Flutter startup script. `flutter build web` / `flutter run` fill in
// the two {{...}} lines with Flutter's own loader code.
{{flutter_js}}
{{flutter_build_config}}

(function () {
  const loader = document.getElementById('loader');
  const status = document.getElementById('loaderStatus');
  const bar = document.getElementById('loaderBar');
  const fills = [
    document.getElementById('fillBack'),
    document.getElementById('fillFront'),
  ];

  // Each loading stage raises the water in the logo, moves the top
  // progress bar, and updates the text.
  function stage(percent, text) {
    if (bar) bar.style.width = percent + '%';
    fills.forEach(function (f, i) {
      // Back wave sits a little higher than the front one.
      if (f) f.style.top = (100 - percent * 0.62 - i * 4) + '%';
    });
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
    }, 400);
  }

  stage(20, 'Checking the waters…');

  // Flutter fires this event after drawing the app for the first time.
  window.addEventListener('flutter-first-frame', hideLoader);

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      stage(60, 'Reading the forecast…');
      const appRunner = await engineInitializer.initializeEngine();
      stage(85, 'Almost there…');
      await appRunner.runApp();
      // Safety net in case the first-frame event is missed.
      setTimeout(hideLoader, 1500);
    },
  });
})();
