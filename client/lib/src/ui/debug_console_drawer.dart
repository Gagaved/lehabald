import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../net/game_network_client.dart';
import '../net/client_log_event.dart';

class DebugConsoleDrawer extends StatefulWidget {
  const DebugConsoleDrawer({
    required this.network,
    required this.onClose,
    super.key,
  });

  final GameNetworkClient network;
  final VoidCallback onClose;

  @override
  State<DebugConsoleDrawer> createState() => _DebugConsoleDrawerState();
}

class _DebugConsoleDrawerState extends State<DebugConsoleDrawer> {
  final _scroll = ScrollController();
  final Set<ClientLogCategory> _filters = ClientLogCategory.values.toSet();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = min(480.0, screen.width * 0.94);
    final oldOffset = _scroll.hasClients ? _scroll.offset : null;
    if (oldOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(oldOffset.clamp(0, _scroll.position.maxScrollExtent));
      });
    }
    final logs = widget.network.logs
        .where((event) => _filters.contains(event.category))
        .toList(growable: false);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: const Color(0x99000000)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 24,
            color: const Color(0xff080c14),
            child: SizedBox(
              width: width,
              height: screen.height,
              child: SafeArea(
                child: Column(
                  children: [
                    _header(),
                    const Divider(height: 1, color: Color(0xff263044)),
                    _filterBar(),
                    _summary(),
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final event = logs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: SelectableText(
                              event.formatted,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.45,
                                color: _colorFor(event.category),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        color: const Color(0xff0d131f),
        child: Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            Text(widget.network.connected ? '● Подключено' : '● Нет связи',
                style: TextStyle(
                    color: widget.network.connected
                        ? const Color(0xff72e6ad)
                        : const Color(0xffff7885))),
            Text('Пинг ${widget.network.pingMs.toStringAsFixed(0)} мс',
                style: const TextStyle(color: Color(0xff8dd9ff))),
            Text('Снапшоты ${widget.network.snapshotVersion}',
                style: const TextStyle(color: Color(0xff9aa8bd))),
          ],
        ),
      );

  Widget _filterBar() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            for (final category in ClientLogCategory.values) ...[
              FilterChip(
                label:
                    Text(category.label, style: const TextStyle(fontSize: 11)),
                selected: _filters.contains(category),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _filters.add(category);
                  } else {
                    _filters.remove(category);
                  }
                }),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 5),
            ],
          ],
        ),
      );

  Color _colorFor(ClientLogCategory category) => switch (category) {
        ClientLogCategory.connection => const Color(0xff72e6ad),
        ClientLogCategory.network => const Color(0xff8dd9ff),
        ClientLogCategory.performance => const Color(0xffffd166),
        ClientLogCategory.protocol => const Color(0xffff7885),
        ClientLogCategory.gameplay => const Color(0xffc7a5ff),
        ClientLogCategory.diagnostic => const Color(0xffc7d0df),
      };

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.terminal_rounded, color: Color(0xff56d6c9)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Консоль',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Сетевые и клиентские события',
                      style: TextStyle(fontSize: 11, color: Color(0xff8290a8))),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Скопировать',
              onPressed: () => Clipboard.setData(
                ClipboardData(text: widget.network.diagnosticsText),
              ),
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: 'Закрыть',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      );
}
