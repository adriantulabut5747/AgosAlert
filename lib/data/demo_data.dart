import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme.dart';

/// ============================================================
/// DEMO DATA — all made-up numbers live here, so a real data
/// source can replace this one file later.
/// Barangay coordinates are real (from OpenStreetMap).
/// ============================================================

const LatLng kMabalacatCenter = LatLng(15.2236, 120.5717); // Poblacion

const List<String> kBarangays = [
  'Atlu-Bola',
  'Bical',
  'Bundagul',
  'Cacutud',
  'Calumpang',
  'Camachiles',
  'Dapdap',
  'Dau',
  'Dolores',
  'Duquit',
  'Lakandula',
  'Mabiga',
  'Macapagal Village',
  'Mamatitang',
  'Mangalit',
  'Marcos Village',
  'Mawaque',
  'Paralayunan',
  'Poblacion',
  'San Francisco',
  'San Joaquin',
  'Santa Ines',
  'Santa Maria',
  'Santo Rosario',
  'Sapang Balen',
  'Sapang Biabas',
  'Tabun',
];

/// Barangay centers found on OpenStreetMap (others fall back to Poblacion).
const Map<String, LatLng> kBarangayPoints = {
  'Atlu-Bola': LatLng(15.2355, 120.5823),
  'Cacutud': LatLng(15.2381, 120.5715),
  'Camachiles': LatLng(15.1924, 120.5861),
  'Dapdap': LatLng(15.2245, 120.6127),
  'Dau': LatLng(15.1761, 120.5887),
  'Dolores': LatLng(15.2161, 120.5589),
  'Duquit': LatLng(15.1779, 120.6014),
  'Lakandula': LatLng(15.1727, 120.5846),
  'Mabiga': LatLng(15.2133, 120.5799),
  'Mamatitang': LatLng(15.2301, 120.5726),
  'Mawaque': LatLng(15.2088, 120.5914),
  'Paralayunan': LatLng(15.2327, 120.6144),
  'Poblacion': LatLng(15.2236, 120.5717),
  'San Francisco': LatLng(15.2177, 120.5786),
  'Santa Ines': LatLng(15.2238, 120.5787),
  'Sapang Biabas': LatLng(15.1988, 120.6026),
  'Tabun': LatLng(15.2477, 120.5659),
};

class FloodZone {
  final String barangay;
  final LatLng point;
  final RiskLevel risk;
  final double waterLevel; // meters
  final String note;
  const FloodZone(
    this.barangay,
    this.point,
    this.risk,
    this.waterLevel,
    this.note,
  );
}

const List<FloodZone> kFloodZones = [
  FloodZone(
    'Dau',
    LatLng(15.1761, 120.5887),
    RiskLevel.high,
    1.8,
    'Low-lying streets near the creek are flooded knee-deep.',
  ),
  FloodZone(
    'Tabun',
    LatLng(15.2477, 120.5659),
    RiskLevel.moderate,
    0.9,
    'Water rising near the Sacobia riverbank.',
  ),
  FloodZone(
    'Mabiga',
    LatLng(15.2133, 120.5799),
    RiskLevel.moderate,
    0.7,
    'Some roads have ankle-to-knee deep water.',
  ),
  FloodZone(
    'Duquit',
    LatLng(15.1779, 120.6014),
    RiskLevel.normal,
    0.2,
    'No flooding reported.',
  ),
  FloodZone(
    'Dolores',
    LatLng(15.2161, 120.5589),
    RiskLevel.normal,
    0.3,
    'Minor puddles only.',
  ),
  FloodZone(
    'Camachiles',
    LatLng(15.1924, 120.5861),
    RiskLevel.moderate,
    0.6,
    'Drainage is slow along the main road.',
  ),
];

class River {
  final String name;
  final String location;
  final double level; // meters
  final double critical; // meters
  final double change; // meters in the last hour (+ rising, - falling)
  const River(this.name, this.location, this.level, this.critical, this.change);

  double get ratio => (level / critical).clamp(0.0, 1.0);
  RiskLevel get risk => ratio >= 0.8
      ? RiskLevel.high
      : ratio >= 0.5
      ? RiskLevel.moderate
      : RiskLevel.normal;
}

const List<River> kRivers = [
  River('Sacobia River', 'Brgy. Tabun', 4.2, 5.0, 0.3),
  River('Abacan River', 'Brgy. Dau', 2.8, 5.0, 0.1),
  River('Sapang Balen Creek', 'Brgy. Sapang Balen', 1.6, 4.0, -0.1),
];

class EvacuationCenter {
  final String name;
  final String barangay;
  final LatLng point;
  final int capacity;
  final int occupants;
  final bool open;
  final double distanceKm;
  final IconData icon;
  final String image; // optional photo in assets/images/
  const EvacuationCenter(
    this.name,
    this.barangay,
    this.point,
    this.capacity,
    this.occupants,
    this.open,
    this.distanceKm,
    this.icon,
    this.image,
  );

  double get fill => occupants / capacity;
}

const List<EvacuationCenter> kEvacCenters = [
  EvacuationCenter(
    'Mabalacat City Sports Complex',
    'Mabiga',
    LatLng(15.2100, 120.5760),
    500,
    186,
    true,
    2.1,
    Icons.stadium_rounded,
    'assets/images/evac_sports_complex.jpg',
  ),
  EvacuationCenter(
    'Mabalacat City Hall Grounds',
    'Poblacion',
    LatLng(15.2230, 120.5735),
    350,
    92,
    true,
    3.0,
    Icons.account_balance_rounded,
    'assets/images/evac_city_hall.jpg',
  ),
  EvacuationCenter(
    'Dau Elementary School',
    'Dau',
    LatLng(15.1790, 120.5860),
    280,
    241,
    true,
    1.4,
    Icons.school_rounded,
    'assets/images/evac_dau_school.jpg',
  ),
  EvacuationCenter(
    'Dolores Covered Court',
    'Dolores',
    LatLng(15.2150, 120.5600),
    200,
    0,
    false,
    3.6,
    Icons.home_work_rounded,
    'assets/images/evac_dolores_court.jpg',
  ),
];

enum AlertCategory {
  flood('Flood', Icons.flood_rounded),
  weather('Weather', Icons.thunderstorm_rounded),
  road('Road', Icons.traffic_rounded),
  shelter('Shelter', Icons.night_shelter_rounded);

  final String label;
  final IconData icon;
  const AlertCategory(this.label, this.icon);
}

class AppAlert {
  final String id;
  final AlertCategory category;
  final RiskLevel severity;
  final String title;
  final String summary;
  final String details;
  final List<String> actions;
  final String area;
  final String source;
  final Duration ago;
  const AppAlert({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.summary,
    required this.details,
    required this.actions,
    required this.area,
    required this.source,
    required this.ago,
  });
}

const List<AppAlert> kAlerts = [
  AppAlert(
    id: 'a1',
    category: AlertCategory.flood,
    severity: RiskLevel.high,
    title: 'Flooding in Brgy. Dau',
    summary: 'Knee-deep water on low-lying streets near the creek.',
    details: 'Water levels in Brgy. Dau have reached around 1.8 m in low-lying areas near the creek. Residents in the affected streets are advised to prepare for possible evacuation.',
    actions: [
      'Move valuables and appliances to higher places',
      'Prepare your go-bag',
      'Evacuate to Dau Elementary School if water keeps rising',
    ],
    area: 'Brgy. Dau',
    source: 'Mabalacat CDRRMO',
    ago: Duration(minutes: 12),
  ),
  AppAlert(
    id: 'a2',
    category: AlertCategory.weather,
    severity: RiskLevel.moderate,
    title: 'Heavy Rainfall Advisory',
    summary: 'Continuous moderate to heavy rain for the next 3 hours.',
    details: 'Moderate to heavy rainfall is expected over Pampanga, including Mabalacat City, within the next 3 hours. Flooding is possible in low-lying areas and near rivers.',
    actions: [
      'Avoid crossing rivers and flooded roads',
      'Keep your phone charged',
      'Monitor updates in AgosAlert',
    ],
    area: 'Mabalacat City',
    source: 'PAGASA',
    ago: Duration(hours: 1, minutes: 5),
  ),
  AppAlert(
    id: 'a3',
    category: AlertCategory.road,
    severity: RiskLevel.moderate,
    title: 'MacArthur Hwy (Dau) not passable',
    summary: 'Light vehicles should take an alternate route.',
    details: 'A section of MacArthur Highway near Dau is flooded and not passable to light vehicles. Traffic is being rerouted.',
    actions: ['Use an alternate route', 'Follow traffic enforcers on site'],
    area: 'Brgy. Dau',
    source: 'Mabalacat Traffic Management',
    ago: Duration(hours: 2, minutes: 20),
  ),
  AppAlert(
    id: 'a4',
    category: AlertCategory.shelter,
    severity: RiskLevel.normal,
    title: 'Evacuation center now open',
    summary: 'Mabalacat City Sports Complex is accepting evacuees.',
    details: 'The Mabalacat City Sports Complex in Brgy. Mabiga is now open as an evacuation center. Bring your go-bag, IDs, and medicines.',
    actions: [
      'Bring IDs and medicines',
      'Register at the help desk on arrival',
    ],
    area: 'Brgy. Mabiga',
    source: 'Mabalacat CDRRMO',
    ago: Duration(hours: 4),
  ),
  AppAlert(
    id: 'a5',
    category: AlertCategory.flood,
    severity: RiskLevel.normal,
    title: 'Water subsiding in Brgy. Duquit',
    summary: 'Streets are passable again.',
    details: 'Floodwater in Brgy. Duquit has fully subsided. Roads are now passable. Watch out for debris and mud.',
    actions: ['Watch out for debris', 'Do not touch fallen power lines'],
    area: 'Brgy. Duquit',
    source: 'Mabalacat CDRRMO',
    ago: Duration(days: 1, hours: 2),
  ),
];

/// IDs of alerts the user has opened (shared by the Alerts tab and the bell).
final ValueNotifier<Set<String>> readAlerts = ValueNotifier({'a5'});

int get unreadAlertCount =>
    kAlerts.where((a) => !readAlerts.value.contains(a.id)).length;

class Hotline {
  final String name;
  final String number;
  final IconData icon;
  final Color color;
  const Hotline(this.name, this.number, this.icon, this.color);
}

const List<Hotline> kHotlines = [
  Hotline(
    'National Emergency Hotline',
    '911',
    Icons.phone_in_talk_rounded,
    kDanger,
  ),
  Hotline('Mabalacat CDRRMO', '0998-999-4357', Icons.shield_rounded, kSkyBlue),
  Hotline(
    'Bureau of Fire Protection',
    '0933-990-9960',
    Icons.local_fire_department_rounded,
    Color(0xFFF97316),
  ),
  Hotline(
    'Mabalacat Police (PNP)',
    '0998-598-5458',
    Icons.local_police_rounded,
    Color(0xFF6366F1),
  ),
  Hotline(
    'Mabalacat City Hall',
    '(045) 649-8620',
    Icons.account_balance_rounded,
    Color(0xFF14B8A6),
  ),
];

class SafetyTip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const SafetyTip(this.icon, this.title, this.body, this.color);
}

const List<SafetyTip> kSafetyTips = [
  SafetyTip(
    Icons.terrain_rounded,
    'Go to higher ground',
    'Move early, before the water rises. Don\'t wait for it to reach your door.',
    kSkyBlue,
  ),
  SafetyTip(
    Icons.power_off_rounded,
    'Switch off the power',
    'Turn off the main breaker if water may enter your home.',
    kCaution,
  ),
  SafetyTip(
    Icons.do_not_step_rounded,
    'Don\'t walk in floodwater',
    'It can hide open drains, sharp debris, strong currents, and live wires.',
    kDanger,
  ),
  SafetyTip(
    Icons.backpack_rounded,
    'Keep a go-bag ready',
    'Water, food, flashlight, medicines, IDs, and a power bank.',
    kSafe,
  ),
];

const List<(String, String)> kGoBagItems = [
  ('Drinking water (3 days)', 'At least 1 gallon per person per day'),
  ('Ready-to-eat food', 'Canned goods and biscuits'),
  ('Flashlight & batteries', ''),
  ('Power bank', 'Fully charged'),
  ('First aid kit & medicines', 'Include maintenance meds'),
  ('IDs & documents', 'In a waterproof pouch'),
  ('Cash', 'Small bills'),
  ('Whistle', 'To signal for help'),
  ('Extra clothes & raincoat', ''),
];

const List<(String, String)> kFaqs = [
  (
    'Where does the weather data come from?',
    'Live weather comes from Open-Meteo, a free weather service, using the coordinates of Mabalacat City.',
  ),
  (
    'Is the flood outlook an official warning?',
    'No. It is estimated from the rainfall forecast. Always follow official warnings from PAGASA and the Mabalacat CDRRMO.',
  ),
  (
    'Are the river levels and flood zones live?',
    'Not yet. Sections marked SAMPLE show demo data while live sensor data is being connected.',
  ),
  (
    'How do I call a hotline?',
    'Open the Assistance tab and tap any hotline. Your phone will ask you to confirm before calling.',
  ),
  (
    'What should I do when a High alert appears?',
    'Follow the recommended actions in the alert, prepare your go-bag, and go to the nearest open evacuation center if told to evacuate.',
  ),
];

String timeAgo(Duration d) {
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
