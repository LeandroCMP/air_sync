import 'package:air_sync/application/ui/theme_extensions.dart';

import 'package:flutter/material.dart';



class MaintenanceHistoryCard extends StatelessWidget {

  const MaintenanceHistoryCard({

    super.key,

    required this.entry,

    this.compact = false,

  });



  final Map<String, dynamic> entry;

  final bool compact;



  @override

  Widget build(BuildContext context) {

    final type = _typeLabel((entry['type'] ?? '').toString());

    final orderId = (entry['orderId'] ?? '').toString();

    final orderStatus = (entry['orderStatus'] ?? '').toString();

    final locationLabel =

        (entry['locationLabel'] ?? entry['location'] ?? '').toString();

    final performedBy = (entry['performedBy'] ?? '').toString();

    final duration = (entry['duration'] ?? '').toString();

    final when = _parseDate(

      entry['at'] ?? entry['date'] ?? entry['performedAt'],

    );

    final whenLabel = when == null ? '-' : _formatDate(when);

    final notes = (entry['notes'] ?? '').toString().trim();

    final services = _serviceList(entry['services'], entry['serviceSummary']);

    final materials = _materialDetails(entry['materials']);

    final billing = _formatMoney(entry['billingTotal']);



    final chipStyle = TextStyle(

      color: Colors.white.withValues(alpha: 0.85),

      fontWeight: FontWeight.w600,

    );



    return Container(

      padding: EdgeInsets.all(compact ? 16 : 20),

      decoration: BoxDecoration(

        color: context.themeSurface,

        borderRadius: BorderRadius.circular(compact ? 14 : 18),

        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),

        boxShadow:

            compact

                ? null

                : [

                  BoxShadow(

                    color: Colors.black.withValues(alpha: 0.25),

                    blurRadius: 18,

                    offset: const Offset(0, 10),

                  ),

                ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              _TimelineBadge(icon: _typeIcon(type)),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      type,

                      style: const TextStyle(

                        color: Colors.white,

                        fontSize: 16,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    if (orderId.isNotEmpty)

                      Padding(

                        padding: const EdgeInsets.only(top: 4),

                        child: Text(

                          orderStatus.isEmpty

                              ? 'OS $orderId'

                              : 'OS $orderId ($orderStatus)',

                          style: TextStyle(

                            color: Colors.white.withValues(alpha: 0.7),

                            fontSize: 13,

                          ),

                        ),

                      ),

                  ],

                ),

              ),

              Text(

                whenLabel,

                style: TextStyle(

                  color: Colors.white.withValues(alpha: 0.7),

                  fontSize: 12,

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          Wrap(

            spacing: 8,

            runSpacing: 8,

            children: [

              if (locationLabel.isNotEmpty)

                _InfoChip(

                  label: 'Local',

                  value: locationLabel,

                  style: chipStyle,

                ),

              if (performedBy.isNotEmpty)

                _InfoChip(

                  label: 'Tcnico',

                  value: performedBy,

                  style: chipStyle,

                ),

              if (duration.isNotEmpty)

                _InfoChip(label: 'Durao', value: duration, style: chipStyle),

              if (billing != null)

                _InfoChip(label: 'Valor', value: billing, style: chipStyle),

            ],

          ),

          if (services.isNotEmpty) ...[

            const SizedBox(height: 14),

            const _SectionTitle('Serviço(s) executado(s)'),

            const SizedBox(height: 4),

            ...services.map((service) => _BulletText(service)),

          ],

          if (notes.isNotEmpty) ...[

            const SizedBox(height: 14),

            const _SectionTitle('Observaes'),

            const SizedBox(height: 4),

            Text(

              notes,

              style: TextStyle(

                color: Colors.white.withValues(alpha: 0.8),

                height: 1.3,

              ),

            ),

          ],

          if (materials.isNotEmpty) ...[

            const SizedBox(height: 14),

            const _SectionTitle('Materiais utilizados'),

            const SizedBox(height: 4),

            ...materials.map((material) => _BulletText(material)),

          ],

        ],

      ),

    );

  }



  static String _typeLabel(String type) {

    switch (type) {

      case 'order_created':

        return 'OS criada';

      case 'order_finished':

        return 'OS finalizada';

      case 'moved':

        return 'Movimentao';

      case 'replaced':

        return 'Substituio';

      default:

        return type.isEmpty ? 'Registro' : type;

    }

  }



  static IconData _typeIcon(String typeLabel) {

    final normalized = typeLabel.toLowerCase();

    if (normalized.contains('final')) return Icons.verified_outlined;

    if (normalized.contains('criad')) return Icons.assignment_outlined;

    if (normalized.contains('mov')) return Icons.sync_alt_outlined;

    if (normalized.contains('sub')) return Icons.swap_horiz_outlined;

    return Icons.build_outlined;

  }



  static DateTime? _parseDate(dynamic value) {

    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is int) {

      if (value > 1e12) {

        return DateTime.fromMillisecondsSinceEpoch(value);

      }

      return DateTime.fromMillisecondsSinceEpoch(value * 1000);

    }

    if (value is num) {

      final millis =

          value.abs() > 1e12 ? value.toInt() : (value * 1000).round();

      return DateTime.fromMillisecondsSinceEpoch(millis);

    }

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);

  }



  static String _formatDate(DateTime date) {

    final d = date.toLocal();

    final day = d.day.toString().padLeft(2, '0');

    final month = d.month.toString().padLeft(2, '0');

    final year = d.year.toString().padLeft(4, '0');

    final hour = d.hour.toString().padLeft(2, '0');

    final minute = d.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';

  }



  static String? _formatMoney(dynamic raw) {

    if (raw == null) return null;

    double? value;

    if (raw is num) {

      value = raw.toDouble();

    } else {

      value = double.tryParse(raw.toString());

    }

    if (value == null || value == 0) return null;

    return 'R\$ ${value.toStringAsFixed(2)}';

  }



  static List<String> _serviceList(dynamic raw, dynamic summary) {

    if (raw is List) {

      final values =

          raw

              .map((e) => e?.toString().trim() ?? '')

              .where((text) => text.isNotEmpty)

              .toList();

      if (values.isNotEmpty) return values.cast<String>();

    }

    final fallback = summary?.toString().trim() ?? '';

    if (fallback.isEmpty) return const [];

    final parts =

        fallback.split(RegExp(r',\\s*')).map((e) => e.trim()).toList();

    return parts.where((text) => text.isNotEmpty).toList();

  }



  static List<String> _materialDetails(dynamic raw) {

    if (raw is! List) return const [];

    final result = <String>[];

    for (final entry in raw.whereType<Map>()) {

      final map = Map<String, dynamic>.from(entry);

      final name =

          (map['name'] ?? map['description'] ?? map['itemName'] ?? 'Material')

              .toString()

              .trim();

      final qtyRaw = map['qty'] ?? map['quantity'];

      final qty =

          qtyRaw is num

              ? qtyRaw.toDouble()

              : double.tryParse(qtyRaw?.toString() ?? '');

      final unit =

          qty == null

              ? ''

              : (qty % 1 == 0

                  ? qty.toStringAsFixed(0)

                  : qty.toStringAsFixed(2));

      final unitPrice = map['unitPrice'] ?? map['price'];

      String priceLabel = '';

      if (unitPrice != null) {

        final parsed =

            unitPrice is num

                ? unitPrice.toDouble()

                : double.tryParse('$unitPrice');

        if (parsed != null && parsed > 0) {

          priceLabel = '  R\$ ${parsed.toStringAsFixed(2)}';

        }

      }

      final qtyLabel = unit.isEmpty ? '' : '  $unit un';

      result.add('$name$qtyLabel$priceLabel');

    }

    return result;

  }

}



class _InfoChip extends StatelessWidget {

  const _InfoChip({

    required this.label,

    required this.value,

    required this.style,

  });



  final String label;

  final String value;

  final TextStyle style;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(12),

      ),

      child: RichText(

        text: TextSpan(

          children: [

            TextSpan(

              text: '$label: ',

              style: style.copyWith(color: Colors.white54),

            ),

            TextSpan(text: value, style: style),

          ],

        ),

      ),

    );

  }

}



class _SectionTitle extends StatelessWidget {

  const _SectionTitle(this.text);



  final String text;



  @override

  Widget build(BuildContext context) {

    return Text(

      text,

      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),

    );

  }

}



class _BulletText extends StatelessWidget {

  const _BulletText(this.text);



  final String text;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 2),

      child: Text(

        '? $text',

        style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),

      ),

    );

  }

}



class _TimelineBadge extends StatelessWidget {

  const _TimelineBadge({required this.icon});



  final IconData icon;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 42,

      height: 42,

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        gradient: LinearGradient(

          colors: [context.themePrimary, context.themePrimary.withValues(alpha: 0.6)],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

      ),

      child: Icon(icon, color: Colors.white, size: 22),

    );

  }

}











