import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'monitoring.dart';
import 'actuator.dart';
import 'settings.dart';
import 'datahelpers.dart';
import 'theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    MonitoringPage(),
    ActuatorPage(),
    SettingsPage(),
  ];

  final List<String> titles = const [
    'Dashboard',
    'Sensors',
    'Actuators',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[selectedIndex])),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Actuators',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('laboratory/status');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StateMessage(
            icon: Icons.cloud_off,
            title: 'Unable to load data',
            message: '${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = snapshot.data!.snapshot.value;

        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        String getData(String key) {
          return data[key]?.toString() ?? 'No Data';
        }

        final known = data['safety'] != null;
        final safety = getData('safety');
        final device = getData('device');

        final safe = safety.toUpperCase() == 'SAFE';
        final online = device.toUpperCase() == 'ONLINE';

        final heroBg = !known
            ? AppColors.neutralBg
            : safe
            ? AppColors.safeBg
            : AppColors.dangerBg;
        final heroFg = !known
            ? AppColors.muted
            : safe
            ? AppColors.safe
            : AppColors.danger;
        final heroIcon = !known
            ? Icons.help_outline
            : safe
            ? Icons.verified_user
            : Icons.warning_amber_rounded;

        final deviceText = online
            ? 'Device online'
            : device == 'No Data'
            ? 'Device status unknown'
            : 'Device offline';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Main focus of the screen: overall safety state
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: heroBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(heroIcon, size: 48, color: heroFg),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laboratory safety',
                              style: TextStyle(
                                fontSize: 14,
                                color: heroFg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              known ? safety : 'No data yet',
                              style: TextStyle(
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: heroFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: online ? AppColors.safe : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deviceText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SectionTitle(
              'Sensors',
              subtitle: 'Latest readings from the lab',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SensorTile(
                    label: 'Gas',
                    value: getData('gas'),
                    icon: Icons.gas_meter_outlined,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    label: 'Light',
                    value: getData('light'),
                    icon: Icons.light_mode_outlined,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    label: 'Distance',
                    value: getData('distance'),
                    unit: 'cm',
                    icon: Icons.social_distance,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),

            const SectionTitle('Actuators', subtitle: 'Current output state'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SensorTile(
                    label: 'LED',
                    value: getData('led'),
                    icon: Icons.lightbulb_outline,
                    color: getData('led').toUpperCase() == 'ON'
                        ? AppColors.safe
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    label: 'Buzzer',
                    value: getData('buzzer'),
                    icon: Icons.notifications_active_outlined,
                    color: getData('buzzer').toUpperCase() == 'ON'
                        ? AppColors.danger
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
