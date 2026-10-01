/* ============================================================
   AgosAlert landing page behaviour. No libraries.
   ============================================================ */
(function () {
  'use strict';

  var root = document.documentElement;
  var reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (id) { return document.getElementById(id); };

  function theme() { return root.dataset.theme === 'light' ? 'light' : 'dark'; }

  /* Where the app lives, relative to this page, with who logged in and
     the current theme. The app reads these (lib/services/session.dart). */
  function appUrl(as) {
    return 'app/?as=' + as + '&theme=' + theme();
  }

  /* ---------------- Theme toggle ---------------- */

  var themeToggle = $('themeToggle');
  function syncThemeButton() {
    themeToggle.setAttribute('aria-label',
      theme() === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
    document.querySelector('meta[name="theme-color"]')
      .setAttribute('content', theme() === 'dark' ? '#060911' : '#E6F1FB');
  }
  function setTheme(t) {
    root.dataset.theme = t;
    try { localStorage.setItem('agos-theme', t); } catch (e) {}
    syncThemeButton();
  }
  // The new theme spreads out in a circle from the button. Browsers
  // without View Transitions (or with reduced motion) just switch.
  themeToggle.addEventListener('click', function () {
    var next = theme() === 'dark' ? 'light' : 'dark';
    if (!document.startViewTransition || reduceMotion) { setTheme(next); return; }
    var box = themeToggle.getBoundingClientRect();
    var x = box.left + box.width / 2, y = box.top + box.height / 2;
    var r = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));
    document.startViewTransition(function () { setTheme(next); }).ready.then(function () {
      root.animate(
        { clipPath: ['circle(0px at ' + x + 'px ' + y + 'px)', 'circle(' + r + 'px at ' + x + 'px ' + y + 'px)'] },
        { duration: 650, easing: 'cubic-bezier(.65, 0, .35, 1)', pseudoElement: '::view-transition-new(root)' }
      );
    });
  });
  syncThemeButton();

  // Coming back from the app (?theme=...): keep that choice, then tidy
  // the address bar so a shared link doesn't carry it along.
  var params = new URLSearchParams(location.search);
  if (params.has('theme')) {
    setTheme(theme());
    history.replaceState(null, '', location.pathname + location.hash);
  }

  /* ---------------- Water lines ----------------
     Same math as the app's WaterLines painter (lib/widgets/common.dart):
     each line a bit lower, longer-waved, and fainter than the last. */

  var waterSvg = $('waterLines');
  function drawWaterLines() {
    var w = waterSvg.clientWidth, h = waterSvg.clientHeight, count = 6, html = '';
    waterSvg.setAttribute('viewBox', '0 0 ' + w + ' ' + h);
    for (var i = 0; i < count; i++) {
      var y = h * (i + 1) / (count + 1);
      var amp = 5 + i * 1.6, wave = 240 + i * 55, phase = i * 1.7;
      var d = 'M0 ' + (y + amp * Math.sin(phase)).toFixed(1);
      for (var x = 8; x <= w + 8; x += 8) {
        d += 'L' + x + ' ' + (y + amp * Math.sin(x / wave * 2 * Math.PI + phase)).toFixed(1);
      }
      html += '<path d="' + d + '" stroke-opacity="' + (1 - i / (count * 1.6)).toFixed(2) + '"/>';
    }
    waterSvg.innerHTML = html;
  }

  /* ---------------- Card scale ----------------
     The weather card is designed at 372px next to a 292px phone; on
     smaller phones it shrinks by the same ratio. */

  var frontPhone = document.querySelector('.device.front .phone');
  function scaleCard() {
    root.style.setProperty('--cs', (frontPhone.offsetWidth / 292).toFixed(3));
  }

  var resizeTimer;
  function onResize() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () { drawWaterLines(); scaleCard(); }, 120);
  }
  drawWaterLines();
  scaleCard();
  addEventListener('resize', onResize);

  /* ---------------- Kapampangan greeting ----------------
     By the time in Mabalacat (Asia/Manila), whatever the visitor's
     own time zone is. */

  var greetings = [
    // [from hour, until hour, Kapampangan, English]
    [5, 11, 'Mayap a abak!', 'Good morning, Mabalaquenians.'],
    [11, 13, 'Mayap a ugtu!', 'Good noon, Mabalaquenians.'],
    [13, 18, 'Mayap a gatpanapun!', 'Good afternoon, Mabalaquenians.'],
  ];
  var night = ['Mayap a bengi!', 'Good evening, Mabalaquenians.'];

  function manilaTime() {
    var parts = new Intl.DateTimeFormat('en-US', {
      timeZone: 'Asia/Manila', hour: 'numeric', minute: '2-digit', hourCycle: 'h23',
    }).formatToParts(new Date());
    var get = function (type) {
      return +parts.filter(function (p) { return p.type === type; })[0].value;
    };
    return { h: get('hour'), m: get('minute') };
  }

  function updateClock() {
    var t = manilaTime();
    var g = night;
    greetings.forEach(function (row) { if (t.h >= row[0] && t.h < row[1]) g = [row[2], row[3]]; });
    $('greeting').innerHTML = '<span class="kap">' + g[0] + '</span> <span class="tr">' + g[1] + '</span>';
    // The phones' status bars show the time in Mabalacat too.
    var clock = (t.h % 12 || 12) + ':' + String(t.m).padStart(2, '0');
    document.querySelectorAll('.sb-time').forEach(function (el) { el.textContent = clock; });
  }
  updateClock();
  setInterval(updateClock, 30 * 1000);

  /* ---------------- Barangay marquee ---------------- */

  var barangays = [
    'Atlu-Bola', 'Bical', 'Bundagul', 'Cacutud', 'Calumpang', 'Camachiles',
    'Dapdap', 'Dau', 'Dolores', 'Duquit', 'Lakandula', 'Mabiga',
    'Macapagal Village', 'Mamatitang', 'Mangalit', 'Marcos Village',
    'Mawaque', 'Paralayunan', 'Poblacion', 'San Francisco', 'San Joaquin',
    'Santa Ines', 'Santa Maria', 'Santo Rosario', 'Sapang Balen',
    'Sapang Biabas', 'Tabun',
  ];
  // Twice in a row: the CSS loop slides by exactly one copy (see landing.css).
  var names = barangays.map(function (b) { return '<span>' + b + '</span>'; }).join('');
  $('barangayTrack').innerHTML = names + names;

  /* ---------------- Live weather ----------------
     Same request and the same rules as lib/services/weather.dart. */

  var WEATHER_URL = 'https://api.open-meteo.com/v1/forecast'
    + '?latitude=15.2236&longitude=120.5714'
    + '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day'
    + '&hourly=precipitation_probability'
    + '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum'
    + '&forecast_days=1&timezone=Asia%2FManila';

  // weatherInfo() in weather.dart: WMO code -> label + icon.
  function weatherInfo(code, isDay) {
    if (code === 0) return isDay ? ['Clear sky', 'sunny'] : ['Clear night', 'clear_night'];
    if (code <= 2) return ['Partly cloudy', isDay ? 'partly_cloudy_day' : 'nights_stay'];
    if (code === 3) return ['Overcast', 'cloud'];
    if (code <= 48) return ['Foggy', 'foggy'];
    if (code <= 57) return ['Drizzle', 'grain'];
    if (code <= 67) return ['Rain', 'water_drop'];
    if (code <= 77) return ['Snow', 'ac_unit'];
    if (code <= 82) return ['Rain showers', 'umbrella'];
    return ['Thunderstorm', 'thunderstorm'];
  }

  // weatherGradient() in weather.dart: the card's colors match the sky.
  function weatherGradient(code, isDay) {
    if (!isDay) return ['#1B2556', '#0B1130'];
    if (code <= 2) return ['#2D7DD2', '#29C5F6'];
    if (code >= 95) return ['#3B3F6B', '#1E2140'];
    if (code >= 51) return ['#1E4E79', '#2D6FA8'];
    return ['#3A5A80', '#5B84B1'];
  }

  // floodOutlook in weather.dart, word for word:
  //   high     - 30 mm+ of rain today, or a storm with a 60%+ rain chance
  //   moderate - 10 mm+, or a 70%+ rain chance
  //   low      - everything else
  // Stormy WMO codes: 95+ thunderstorm, 65 heavy rain, 82 violent showers.
  function floodOutlook(code, rainSum, rainChance) {
    var stormy = code >= 95 || code === 65 || code === 82;
    if (rainSum >= 30 || (stormy && rainChance >= 60)) return ['high', 'High risk'];
    if (rainSum >= 10 || rainChance >= 70) return ['moderate', 'Moderate risk'];
    return ['low', 'Low risk'];
  }

  function formatTime(iso) {
    // "2026-09-28T21:00" is already Manila time (timezone=Asia/Manila).
    var hh = +iso.slice(11, 13), mm = iso.slice(14, 16);
    return (hh % 12 || 12) + ':' + mm + ' ' + (hh < 12 ? 'AM' : 'PM');
  }

  // The big number counts up from 0, like the app's card.
  function countUp(el, to) {
    if (reduceMotion) { el.textContent = Math.round(to); return; }
    var start = performance.now(), dur = 1100;
    (function frame(now) {
      var p = Math.min(1, (now - start) / dur);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(to * eased);
      if (p < 1) requestAnimationFrame(frame);
    })(start);
  }

  var card = $('weatherCard');
  var firstLoad = true;

  function showWeather(json) {
    var cur = json.current, day = json.daily;
    var code = cur.weather_code, isDay = cur.is_day === 1;
    var info = weatherInfo(code, isDay), grad = weatherGradient(code, isDay);
    var max = Math.round(day.temperature_2m_max[0]), min = Math.round(day.temperature_2m_min[0]);
    // rainChance is the day's highest hour (used by the flood outlook);
    // the card shows this hour's chance, so it changes during the day.
    var rainChance = day.precipitation_probability_max[0] || 0;
    var hourIdx = json.hourly.time.indexOf(cur.time.slice(0, 13) + ':00');
    var chanceNow = hourIdx >= 0 ? json.hourly.precipitation_probability[hourIdx] : rainChance;
    var rainSum = (day.precipitation_sum[0] || 0).toFixed(1);

    card.style.background = 'linear-gradient(135deg, ' + grad[0] + ', ' + grad[1] + ')';
    $('wTime').textContent = formatTime(cur.time);
    $('wLabel').textContent = info[0];
    $('wIcon').textContent = info[1];
    $('wSub').textContent = 'H ' + max + '°  ·  L ' + min + '°  ·  Feels ' + Math.round(cur.apparent_temperature) + '°';
    $('wRainChance').textContent = chanceNow + '%';
    $('wRainSum').textContent = rainSum + ' mm';
    $('wHumidity').textContent = cur.relative_humidity_2m + '%';
    $('wWind').textContent = Math.round(cur.wind_speed_10m) + ' km/h';

    // Wait for the card's own entrance before counting up the first time.
    var temp = cur.temperature_2m;
    if (firstLoad) setTimeout(function () { countUp($('wTemp'), temp); }, reduceMotion ? 0 : 1100);
    else $('wTemp').textContent = Math.round(temp);
    firstLoad = false;
    card.dataset.state = 'ready';

    var outlook = floodOutlook(code, day.precipitation_sum[0] || 0, rainChance);
    $('outlookChip').dataset.risk = outlook[0];
    $('oLevel').textContent = outlook[1];

    // "How it works", cards 1 and 2: the same numbers, and which rule
    // matched today.
    $('hwChance').textContent = rainChance + '%';
    $('hwSum').textContent = rainSum + ' mm';
    $('hwCode').textContent = code + ' · ' + info[0].toLowerCase();
    $('hwTime').textContent = 'Live · updated ' + formatTime(cur.time);
    document.querySelectorAll('.rule').forEach(function (r) {
      r.classList.toggle('is-today', r.dataset.level === outlook[0]);
    });

    $('weatherText').textContent = 'Live weather in Mabalacat City: ' + Math.round(temp) + ' degrees, '
      + info[0].toLowerCase() + ', ' + rainChance + '% chance of rain today. Flood outlook today: '
      + outlook[1].toLowerCase() + '.';
  }

  function loadWeather() {
    var ctrl = new AbortController();
    var timer = setTimeout(function () { ctrl.abort(); }, 10000);
    fetch(WEATHER_URL, { signal: ctrl.signal })
      .then(function (res) {
        if (!res.ok) throw new Error('Weather API returned ' + res.status);
        return res.json();
      })
      .then(showWeather)
      .catch(function () {
        // Keep the last good reading if there is one.
        if (card.dataset.state === 'ready') return;
        card.dataset.state = 'error';
        $('wLabel').textContent = 'Weather unavailable';
        $('wSub').textContent = 'Check your connection and reload.';
        $('outlookChip').dataset.risk = 'error';
        $('oLevel').textContent = 'Unavailable';
      })
      .finally(function () { clearTimeout(timer); });
  }
  loadWeather();
  setInterval(loadWeather, 10 * 60 * 1000); // Open-Meteo updates every 15 min

  /* ---------------- Mouse tilt ----------------
     The phones lean toward the cursor. Mouse only (no hover on
     touch screens), and not for reduced-motion visitors. Each frame
     moves 8% of the way to the target, which smooths out jumpy mice. */

  var stage = $('stage');
  if (!reduceMotion && matchMedia('(hover: hover) and (pointer: fine)').matches) {
    var target = { x: 0, y: 0 }, now = { x: 0, y: 0 }, running = false;
    var tick = function () {
      now.x += (target.x - now.x) * 0.08;
      now.y += (target.y - now.y) * 0.08;
      stage.style.setProperty('--tx', now.x.toFixed(4));
      stage.style.setProperty('--ty', now.y.toFixed(4));
      if (Math.abs(target.x - now.x) + Math.abs(target.y - now.y) > 0.001) {
        requestAnimationFrame(tick);
      } else {
        running = false;
      }
    };
    var kick = function () { if (!running) { running = true; requestAnimationFrame(tick); } };
    addEventListener('pointermove', function (e) {
      target.x = (e.clientX / innerWidth - 0.5) * 2;   // -1 left ... 1 right
      target.y = (e.clientY / innerHeight - 0.5) * 2;  // -1 top  ... 1 bottom
      kick();
    });
    document.addEventListener('pointerleave', function () { target.x = 0; target.y = 0; kick(); });
  }

  /* ---------------- Toast ---------------- */

  var toast = $('toast'), toastTimer;
  function showToast(text, link) {
    toast.innerHTML = '';
    var span = document.createElement('span');
    span.textContent = text;
    toast.appendChild(span);
    if (link) {
      var a = document.createElement('a');
      a.href = link.href;
      a.textContent = link.label;
      toast.appendChild(a);
    }
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toast.classList.remove('show'); }, 5000);
  }

  document.querySelectorAll('.store').forEach(function (btn) {
    btn.addEventListener('click', function () {
      showToast('The ' + btn.dataset.store + ' app is coming soon.',
        { label: 'Use the web app →', href: appUrl('guest') });
    });
  });

  /* ---------------- Login popup ---------------- */

  var modal = $('loginModal');
  var form = $('loginForm');
  var submit = $('loginSubmit');

  var regForm = $('registerForm');
  var regSubmit = $('registerSubmit');
  var regError = $('registerError');

  // The popup holds two cards, login and register; only one is shown.
  function showCard(which) {
    var reg = which === 'register';
    form.hidden = reg;
    regForm.hidden = !reg;
    regError.hidden = true;
    modal.setAttribute('aria-labelledby', reg ? 'registerTitle' : 'loginTitle');
    if (matchMedia('(pointer: fine)').matches) (reg ? regForm.fullName : form.email).focus();
  }

  function openLogin() {
    if (modal.open) return;
    modal.classList.remove('closing');
    form.hidden = false;
    regForm.hidden = true;
    modal.showModal();
    // Put the cursor in the email field on computers. On phones that
    // would pop the keyboard up over the popup straight away.
    if (matchMedia('(pointer: fine)').matches) form.email.focus();
  }

  function closeLogin() {
    if (!modal.open || modal.classList.contains('closing')) return;
    if (reduceMotion) { modal.close(); return; }
    modal.classList.add('closing');
    // Only the visible card animates (the other one is display:none).
    modal.querySelector('.modal-card:not([hidden])').addEventListener('animationend', function done() {
      modal.classList.remove('closing');
      modal.close();
    }, { once: true });
  }

  $('openLogin').addEventListener('click', openLogin);
  $('closeLogin').addEventListener('click', closeLogin);
  // Esc: play the closing animation instead of vanishing instantly.
  modal.addEventListener('cancel', function (e) { e.preventDefault(); closeLogin(); });
  // A click on the dark backdrop lands on the <dialog> itself.
  modal.addEventListener('click', function (e) { if (e.target === modal) closeLogin(); });

  $('togglePassword').addEventListener('click', function () {
    var input = $('password'), show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    this.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    this.querySelector('.ms').textContent = show ? 'visibility' : 'visibility_off';
  });

  $('forgot').addEventListener('click', function () {
    showToast('Password reset isn’t available in the demo yet.');
  });

  $('showRegister').addEventListener('click', function () { showCard('register'); });
  $('showLogin').addEventListener('click', function () { showCard('login'); });
  $('closeRegister').addEventListener('click', closeLogin);

  $('toggleRegPassword').addEventListener('click', function () {
    var input = $('regPassword'), show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    this.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    this.querySelector('.ms').textContent = show ? 'visibility' : 'visibility_off';
  });

  // Returns the first problem with the form, or '' when it's fine.
  function registerProblem() {
    var f = regForm;
    if (f.fullName.value.trim().length < 2) return 'Enter your full name.';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(f.email.value.trim())) return 'Enter a valid email address.';
    var phone = f.phone.value.replace(/[\s-]/g, '');
    if (phone && !/^\+?\d{10,14}$/.test(phone)) return 'Phone number should be 10 to 14 digits, or leave it empty.';
    if (!f.barangay.value) return 'Choose the barangay where you live.';
    if (f.password.value.length < 8) return 'Password must be at least 8 characters.';
    if (f.password.value !== f.confirm.value) return 'The two passwords don’t match.';
    return '';
  }

  // Demo registration: checked, but nothing is saved or sent.
  regForm.addEventListener('submit', function (e) {
    e.preventDefault();
    var problem = registerProblem();
    regError.hidden = !problem;
    regError.textContent = problem;
    if (!problem) enterApp('user', regSubmit);
  });

  // Demo login: no checks, nothing sent. A short pause so the button's
  // loading state is visible, then into the app.
  function enterApp(as, btn) {
    btn = btn || submit;
    btn.classList.add('loading');
    btn.disabled = true;
    setTimeout(function () { location.href = appUrl(as); }, reduceMotion ? 0 : 700);
  }
  form.addEventListener('submit', function (e) { e.preventDefault(); enterApp('user'); });
  $('googleLogin').addEventListener('click', function () { enterApp('user'); });
  $('guestLogin').addEventListener('click', function () { enterApp('guest'); });
  // Top bar "Continue as guest": same as above, without opening the popup.
  // Updated on click so it carries the theme picked on this page.
  $('guestTop').addEventListener('click', function () { this.href = appUrl('guest'); });

  // Coming back with the Back button restores this page from memory with
  // the button still spinning. pageshow + persisted = restored that way.
  addEventListener('pageshow', function (e) {
    if (e.persisted) {
      [submit, regSubmit].forEach(function (b) { b.classList.remove('loading'); b.disabled = false; });
    }
  });

  /* ---------------- Fade-in on scroll ----------------
     Each .reveal block fades up the first time a bit of it is on
     screen. The barangay map uses the same class for its dots. */

  var revealer = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) { e.target.classList.add('in'); revealer.unobserve(e.target); }
    });
  }, { rootMargin: '0px 0px -12% 0px' });
  document.querySelectorAll('.reveal').forEach(function (el) { revealer.observe(el); });

  /* ---------------- 02 Hotlines ---------------- */

  var hotItems = document.querySelectorAll('#hotList li');
  hotItems.forEach(function (li) {
    li.style.setProperty('--tint', li.dataset.color);
    var number = li.querySelector('.hot-num').textContent;
    li.querySelector('.hot-copy').addEventListener('click', function () {
      navigator.clipboard.writeText(number).then(
        function () { showToast('Copied ' + number + '.'); },
        function () { showToast('Couldn’t copy. The number is ' + number + '.'); }
      );
    });
  });

  // One .vcf file with a contact card per hotline. Phones offer to add
  // them all when the file is opened.
  $('saveContacts').addEventListener('click', function () {
    var cards = Array.prototype.map.call(hotItems, function (li) {
      return ['BEGIN:VCARD', 'VERSION:3.0',
        'FN:' + li.dataset.name, 'N:;' + li.dataset.name + ';;;',
        'ORG:Emergency hotline (Mabalacat)',
        'TEL;TYPE=VOICE:' + li.dataset.tel,
        'NOTE:Saved from AgosAlert', 'END:VCARD'].join('\r\n');
    });
    var blob = new Blob([cards.join('\r\n') + '\r\n'], { type: 'text/vcard' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'Mabalacat emergency hotlines.vcf';
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
    showToast('Contacts file downloaded. Open it to add all seven numbers.');
  });

  // The app's "Log in" links here with #login: open the popup right away.
  if (location.hash === '#login') {
    history.replaceState(null, '', location.pathname + location.search);
    openLogin();
  }
})();
