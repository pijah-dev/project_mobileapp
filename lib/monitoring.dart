import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'datahelpers.dart';
import 'theme.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  Widget _mini(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusRef = FirebaseDatabase.instance.ref('laboratory/status');
    final historyRef =
    FirebaseDatabase.instance.ref('laboratory/history/sensors');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Text(
          'Current readings, updated live',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),

        StreamBuilder<DatabaseEvent>(
          stream: statusRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Unable to load current readings');
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

            return Row(
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
            );
          },
        ),

        const SectionTitle('History', subtitle: 'Last 30 records'),

        StreamBuilder<DatabaseEvent>(
          stream: historyRef.limitToLast(30).onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Unable to load history');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final raw = snapshot.data!.snapshot.value;

            if (raw == null) {
              return const Panel(
                child: Text(
                  'No sensor history yet. Records appear once the device sends data.',
                  style: TextStyle(color: AppColors.muted),
                ),
              );
            }

            final data = Map<dynamic, dynamic>.from(raw as Map);
            final entries = data.entries.toList().reversed.toList();

            return Column(
              children: entries.map((entry) {
                final item = Map<dynamic, dynamic>.from(entry.value as Map);

                final gas = item['gas'] ?? '-';
                final light = item['light'] ?? '-';
                final distance = item['distance'] ?? '-';
                final time = formatTimestamp(item['timestamp']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _mini('Gas', '$gas'),
                            _mini('Light', '$light'),
                            _mini('Distance', '$distance cm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
