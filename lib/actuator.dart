import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'datahelpers.dart';
import 'theme.dart';

class ActuatorPage extends StatelessWidget {
  const ActuatorPage({super.key});

  Future<void> controlActuator(
      BuildContext context,
      String name,
      String command,
      ) async {
    try {
      final ref = FirebaseDatabase.instance.ref('laboratory/actuators/$name');

      // Send command to ESP32
      await ref.child('command').set(command);

      // Save actuator history
      await FirebaseDatabase.instance
          .ref('laboratory/history/actuators')
          .push()
          .set({
        'actuator': name.toUpperCase(),
        'command': command,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command failed: $e')),
      );
    }
  }

  Widget actuatorControl(
      BuildContext context,
      String name,
      String label,
      IconData icon,
      ) {
    final ref = FirebaseDatabase.instance.ref(
      'laboratory/actuators/$name/status',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        final status = snapshot.data?.snapshot.value?.toString() ?? 'UNKNOWN';
        final isOn = status.toUpperCase() == 'ON';
        final isOff = status.toUpperCase() == 'OFF';

        final statusColor = isOn
            ? AppColors.safe
            : isOff
            ? AppColors.danger
            : AppColors.muted;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOn ? AppColors.safeBg : AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: isOn ? AppColors.safe : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 9, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: isOn
                          ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.safe,
                        ),
                        onPressed: () =>
                            controlActuator(context, name, 'ON'),
                        child: const Text('On'),
                      )
                          : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.safe,
                          side: const BorderSide(color: AppColors.safe),
                        ),
                        onPressed: () =>
                            controlActuator(context, name, 'ON'),
                        child: const Text('On'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: isOff
                          ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () =>
                            controlActuator(context, name, 'OFF'),
                        child: const Text('Off'),
                      )
                          : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side:
                          const BorderSide(color: AppColors.danger),
                        ),
                        onPressed: () =>
                            controlActuator(context, name, 'OFF'),
                        child: const Text('Off'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyRef =
    FirebaseDatabase.instance.ref('laboratory/history/actuators');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Text(
          'Switch output devices on or off',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),

        actuatorControl(context, 'led', 'LED', Icons.lightbulb_outline),
        actuatorControl(
          context,
          'buzzer',
          'Buzzer',
          Icons.notifications_active_outlined,
        ),

        const SectionTitle('History', subtitle: 'Last 30 commands'),

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
                  'No commands yet. Turn an actuator on or off and it shows up here.',
                  style: TextStyle(color: AppColors.muted),
                ),
              );
            }

            final data = Map<dynamic, dynamic>.from(raw as Map);
            final entries = data.entries.toList().reversed.toList();

            return Column(
              children: entries.map((entry) {
                final item = Map<dynamic, dynamic>.from(entry.value as Map);

                final name = item['actuator'] ?? '-';
                final command = item['command'] ?? '-';
                final time = formatTimestamp(item['timestamp']);

                return historyCard(
                  '$name',
                  'set to $command',
                  time,
                  Icons.history,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
