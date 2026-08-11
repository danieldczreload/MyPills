import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/notifications/data/services/device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kOemDialogShownKey = 'mypills.oem_setup_shown_v1';

/// Shows the OEM-specific setup dialog once per device, tracked in
/// [SharedPreferences]. No-op for stock / Samsung (which work out of the box
/// once `ignoreBatteryOptimizations` is granted).
Future<void> maybeShowOemSetup({
  required BuildContext context,
  required SharedPreferences prefs,
  required OemFamily family,
}) async {
  if (!family.needsManualSetup) return;
  if (prefs.getBool(_kOemDialogShownKey) ?? false) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OemSetupDialog(family: family),
  );
  await prefs.setBool(_kOemDialogShownKey, true);
}

class _OemContent {
  const _OemContent({
    required this.title,
    required this.intro,
    required this.steps,
  });

  final String title;
  final String intro;
  final List<({String title, String body})> steps;
}

_OemContent _contentFor(OemFamily f) => switch (f) {
  OemFamily.huawei => const _OemContent(
    title: 'Configurar tu Huawei',
    intro:
        'EMUI bloquea las notificaciones en segundo plano por defecto. '
        'Para que MyPills te avise a tiempo:',
    steps: [
      (
        title: 'Inicio de aplicación',
        body:
            'Ajustes → Aplicaciones → MyPills → Batería → Inicio de '
            'aplicación. Cambia a "Gestionar manualmente" y activa las tres '
            'opciones (Inicio automático, Inicio secundario, Ejecutar en '
            'segundo plano).',
      ),
      (
        title: 'Pantalla de bloqueo',
        body:
            'Ajustes → Notificaciones → MyPills → activa "Pantalla de '
            'bloqueo" y "Banner".',
      ),
    ],
  ),
  OemFamily.xiaomi => const _OemContent(
    title: 'Configurar tu Xiaomi',
    intro:
        'MIUI / HyperOS bloquea apps en background con mucha agresividad. '
        'Configura lo siguiente:',
    steps: [
      (
        title: 'Inicio automático',
        body: 'Ajustes → Apps → Permisos → Inicio automático → activa MyPills.',
      ),
      (
        title: 'Sin restricción de batería',
        body:
            'Ajustes → Apps → MyPills → Ahorro de batería → Sin '
            'restricciones.',
      ),
      (
        title: 'Bloquear en multitarea',
        body:
            'Abre la pantalla de apps recientes, mantén pulsada la tarjeta '
            'de MyPills y elige "Bloquear" (icono de candado).',
      ),
    ],
  ),
  OemFamily.oppo => const _OemContent(
    title: 'Configurar tu OPPO/Realme',
    intro:
        'ColorOS limita procesos en background. Activa lo siguiente para '
        'que las notificaciones lleguen a tiempo:',
    steps: [
      (
        title: 'Inicio automático',
        body:
            'Ajustes → Batería → Optimización avanzada → Inicio automático '
            '→ activa MyPills.',
      ),
      (
        title: 'No optimizar batería',
        body:
            'Ajustes → Batería → Uso de batería → MyPills → "Permitir '
            'actividad en segundo plano".',
      ),
      (
        title: 'Bloquear en multitarea',
        body:
            'En apps recientes, desliza hacia abajo en la tarjeta de '
            'MyPills para fijarla.',
      ),
    ],
  ),
  OemFamily.vivo => const _OemContent(
    title: 'Configurar tu Vivo',
    intro:
        'FunTouch / OriginOS detiene apps en background. Activa lo siguiente:',
    steps: [
      (
        title: 'Inicio automático',
        body:
            'Ajustes → Más ajustes → Permisos → Inicio automático → activa '
            'MyPills.',
      ),
      (
        title: 'Alto consumo en background',
        body:
            'Ajustes → Batería → Alto consumo en background → permite '
            'MyPills.',
      ),
    ],
  ),
  OemFamily.oneplus => const _OemContent(
    title: 'Configurar tu OnePlus',
    intro:
        'OxygenOS reciente comparte limitaciones con ColorOS. Activa lo '
        'siguiente:',
    steps: [
      (
        title: 'No optimizar batería',
        body:
            'Ajustes → Batería → Optimización de batería → MyPills → No '
            'optimizar.',
      ),
      (
        title: 'Actividad en background',
        body:
            'Ajustes → Apps → MyPills → Batería → "Permitir actividad en '
            'segundo plano".',
      ),
    ],
  ),
  // Should not be reached because needsManualSetup gates these out.
  OemFamily.stock || OemFamily.samsung => const _OemContent(
    title: 'Configurar notificaciones',
    intro: 'Tu dispositivo no requiere configuración adicional.',
    steps: [],
  ),
};

class _OemSetupDialog extends StatefulWidget {
  const _OemSetupDialog({required this.family});

  final OemFamily family;

  @override
  State<_OemSetupDialog> createState() => _OemSetupDialogState();
}

class _OemSetupDialogState extends State<_OemSetupDialog> {
  bool _batteryRequested = false;
  bool _batteryGranted = false;

  Future<void> _requestBattery() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (!mounted) return;
    setState(() {
      _batteryRequested = true;
      _batteryGranted = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sereneTheme = theme.extension<SereneTheme>()!;
    final content = _contentFor(widget.family);

    final batteryStep = (
      title: 'Ignorar optimización de batería',
      body: 'Pulsa el botón de abajo. Acepta cuando el sistema lo pida.',
    );
    final allSteps = [...content.steps, batteryStep];

    return AlertDialog(
      title: Text(content.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content.intro),
            SizedBox(height: sereneTheme.spacing.md),
            for (var i = 0; i < allSteps.length; i++)
              _Step(
                number: '${i + 1}',
                title: allSteps[i].title,
                body: allSteps[i].body,
              ),
            SizedBox(height: sereneTheme.spacing.md),
            ElevatedButton.icon(
              onPressed: _requestBattery,
              icon: Icon(_batteryGranted ? Icons.check : Icons.battery_saver),
              label: Text(
                _batteryGranted
                    ? 'Batería: concedido'
                    : 'Pedir ignorar batería',
              ),
            ),
            if (_batteryRequested && !_batteryGranted)
              Padding(
                padding: EdgeInsets.only(top: sereneTheme.spacing.sm),
                child: Text(
                  'No se concedió. Puedes habilitarlo manualmente en '
                  'Ajustes → Batería.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sereneTheme = theme.extension<SereneTheme>()!;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: sereneTheme.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: sereneTheme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
