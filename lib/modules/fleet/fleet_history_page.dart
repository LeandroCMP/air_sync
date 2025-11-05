import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FleetHistoryPage extends StatefulWidget {
  final String vehicleId;
  final String title;
  const FleetHistoryPage({super.key, required this.vehicleId, required this.title});

  @override
  State<FleetHistoryPage> createState() => _FleetHistoryPageState();
}

class _FleetHistoryPageState extends State<FleetHistoryPage> {
  final _svc = Get.find<FleetService>();
  final _df = DateFormat('dd/MM/yyyy HH:mm');
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _scroll = ScrollController();

  final List<Map<String, dynamic>> _events = [];
  bool _loading = false;
  bool _initialLoaded = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 30;

  final Set<String> _typesSel = {'check', 'fuel', 'maintenance'};
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load(first: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200 && !_loading && _hasMore) {
        _load();
      }
    });
  }

  Future<void> _load({bool first = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page = first ? 1 : _page;
      final fetched = await _svc.listEvents(
        widget.vehicleId,
        page: page,
        limit: _limit,
        types: _typesSel.isEmpty ? null : _typesSel.toList(),
        from: _from,
        to: _to,
        sort: 'at',
        order: 'desc',
      );
      if (first) {
        _events
          ..clear()
          ..addAll(fetched);
        _page = 2;
      } else {
        _events.addAll(fetched);
        _page += 1;
      }
      _hasMore = fetched.length >= _limit;
    } finally {
      setState(() {
        _loading = false;
        _initialLoaded = true;
      });
    }
  }

  Future<void> _refresh() async {
    _hasMore = true;
    _page = 1;
    await _load(first: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Histórico • ${widget.title}', style: const TextStyle(color: Colors.white)),
      ),
      body: !_initialLoaded
          ? const LinearProgressIndicator(minHeight: 2)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  _buildFilters(context),
                  Expanded(
                    child: _events.isEmpty
                        ?  ListView(children: [SizedBox(height: 240), Center(child: Text('Sem eventos', style: TextStyle(color: Colors.white70)))])
                        : ListView.separated(
                            controller: _scroll,
                            itemCount: _events.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              if (i >= _events.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                                );
                              }
                              final e = _events[i];
                              final type = (e['type'] ?? e['eventType'] ?? '').toString();
                              final atRaw = e['at'] ?? e['createdAt'] ?? e['date'] ?? e['timestamp'];
                              DateTime? at;
                              if (atRaw is String) at = DateTime.tryParse(atRaw);
                              if (atRaw is int) at = DateTime.fromMillisecondsSinceEpoch(atRaw);
                              final atStr = at != null ? _df.format(at.toLocal()) : '';
                              final odo = e['km'] ?? e['atKm'] ?? e['odometer'] ?? e['odo'] ?? '';

                              final showHeader = _shouldShowHeader(i, at);
                              final header = showHeader && at != null
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                      child: Text(DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(at.toLocal()),
                                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                    )
                                  : const SizedBox.shrink();

                              String subtitle = atStr;
                              if (odo.toString().isNotEmpty) subtitle += '  •  Odômetro: $odo';
                              if (type == 'fuel') {
                                final liters = e['liters'] ?? e['qty'];
                                final cost = e['cost'] ?? e['price'] ?? e['total'];
                                final fType = e['fuelType'];
                                final costStr = cost is num ? _money.format(cost) : (cost?.toString() ?? '-');
                                subtitle += '  •  Litros: ${liters ?? '-'}  •  Custo: $costStr';
                                if ((fType ?? '').toString().isNotEmpty) subtitle += '  •  Tipo: $fType';
                              }
                              if (type == 'maintenance') {
                                final cost = e['cost'];
                                if (cost != null) {
                                  final costStr = cost is num ? _money.format(cost) : cost.toString();
                                  subtitle += '  •  Custo: $costStr';
                                }
                                final notes = e['notes'];
                                if ((notes ?? '').toString().isNotEmpty) subtitle += '  •  ${notes.toString()}';
                              }
                              if (type == 'check') {
                                final fl = e['fuelLevel'];
                                if (fl != null) subtitle += '  •  Combustível: ${fl}%';
                                final notes = e['notes'];
                                if ((notes ?? '').toString().isNotEmpty) subtitle += '  •  ${notes.toString()}';
                              }

                              final tile = ListTile(
                                title: Text(_titleFor(type), style: const TextStyle(color: Colors.white)),
                                subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
                              );

                              if (showHeader) {
                                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, tile]);
                              }
                              return tile;
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _typeChip('check', 'Check'),
              _typeChip('fuel', 'Abastecimento'),
              _typeChip('maintenance', 'Manutenção'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _from ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() => _from = DateTime(picked.year, picked.month, picked.day));
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_from == null ? 'De' : DateFormat('dd/MM/yyyy').format(_from!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _to ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() => _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(_to == null ? 'Até' : DateFormat('dd/MM/yyyy').format(_to!)),
                ),
              ),
              IconButton(
                tooltip: 'Limpar filtros',
                onPressed: () {
                  setState(() {
                    _typesSel..clear()..addAll(['check', 'fuel', 'maintenance']);
                    _from = null;
                    _to = null;
                  });
                  _refresh();
                },
                icon: const Icon(Icons.filter_alt_off),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String key, String label) {
    final selected = _typesSel.contains(key);
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (val) {
        setState(() {
          if (val) {
            _typesSel.add(key);
          } else {
            _typesSel.remove(key);
          }
        });
        _refresh();
      },
    );
  }

  bool _shouldShowHeader(int index, DateTime? at) {
    if (at == null) return false;
    if (index == 0) return true;
    DateTime? prevAt;
    final prevRaw = _events[index - 1]['at'] ?? _events[index - 1]['createdAt'] ?? _events[index - 1]['date'] ?? _events[index - 1]['timestamp'];
    if (prevRaw is String) prevAt = DateTime.tryParse(prevRaw);
    if (prevRaw is int) prevAt = DateTime.fromMillisecondsSinceEpoch(prevRaw);
    if (prevAt == null) return true;
    final d1 = DateTime(at.year, at.month, at.day);
    final d2 = DateTime(prevAt.year, prevAt.month, prevAt.day);
    return d1 != d2;
  }

  String _titleFor(String type) {
    switch (type.toLowerCase()) {
      case 'fuel':
        return 'Abastecimento';
      case 'maintenance':
        return 'Manutenção';
      case 'check':
        return 'Check';
      default:
        return type.isEmpty ? 'Evento' : type;
    }
  }
}


