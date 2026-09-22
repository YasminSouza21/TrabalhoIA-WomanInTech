import 'package:flutter/material.dart';

import 'api_client.dart';

void main() => runApp(GradeApp(client: ApiClient()));

class GradeApp extends StatelessWidget {
  const GradeApp({super.key, required this.client});
  final ApiClient client;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4a376f)),
      useMaterial3: true,
    ),
    home: GradePage(client: client),
  );
}

class GradePage extends StatefulWidget {
  const GradePage({super.key, required this.client});
  final ApiClient client;
  @override
  State<GradePage> createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> {
  String selectedUser = 'p-carla';
  String type = '', day = '';
  List<Map<String, dynamic>> items = const [];
  List<Map<String, dynamic>> availableRooms = const [];
  String? error;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    widget.client.user = selectedUser;
    try {
      final results = await Future.wait([
        widget.client.activities(type: type, day: day),
        widget.client.rooms(),
      ]);
      items = results[0];
      availableRooms = results[1];
    } on ApiFailure catch (e) {
      error = e.code;
    } catch (_) {
      error = 'Não foi possível conectar à API';
    }
    if (mounted) setState(() => loading = false);
  }

  AppUser get currentUser =>
      ApiClient.knownUsers.firstWhere((user) => user.id == selectedUser);
  bool get organization => currentUser.role == 'organizacao';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Semana Acadêmica 2026'),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: selectedUser,
            dropdownColor: Theme.of(context).colorScheme.surface,
            items: ApiClient.knownUsers
                .map(
                  (user) => DropdownMenuItem(
                    value: user.id,
                    child: Text('${user.name} (${user.role})'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedUser = value);
              widget.client.user = value;
              _load();
            },
          ),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Grade de atividades',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Consulte horários, salas, vagas e situação em tempo real.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DropdownButton<String>(
                value: type,
                hint: const Text('Todos os tipos'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos os tipos')),
                  DropdownMenuItem(value: 'palestra', child: Text('Palestras')),
                  DropdownMenuItem(
                    value: 'minicurso',
                    child: Text('Minicursos'),
                  ),
                ],
                onChanged: (value) {
                  type = value ?? '';
                  _load();
                },
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Dia (AAAA-MM-DD)',
                  ),
                  onChanged: (value) => day = value,
                  onSubmitted: (_) => _load(),
                ),
              ),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search),
                label: const Text('Atualizar'),
              ),
              if (organization)
                OutlinedButton.icon(
                  onPressed: () => _showEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova atividade'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading && error != null)
            _Message(icon: Icons.error_outline, text: error!, action: _load),
          if (!loading && error == null && items.isEmpty)
            const _Message(
              icon: Icons.event_busy,
              text: 'Nenhuma atividade encontrada.',
            ),
          if (!loading) ...items.map(_card),
        ],
      ),
    ),
  );
  Widget _card(Map<String, dynamic> json) {
    final item = Activity(json);
    final room = _findRoom(item.roomId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text(
          '${item.type}  •  ${room?.name ?? item.roomId}  •  ${item.duration} min',
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(item.situation)),
            Text('${item.slots} vagas'),
            if (organization)
              IconButton(
                onPressed: () => _showEditor(item),
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        onTap: () => _showDetail(item),
      ),
    );
  }

  void _showDetail(Activity item) => showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      title: Text(item.title),
      content: SingleChildScrollView(
        child: Text(
          'Tipo: ${item.type}\n'
          'Sala: ${_roomDescription(item.roomId)}\n'
          'Carga: ${item.duration} minutos\n'
          'Situação: ${item.situation}\n'
          'Vagas restantes: ${item.json['vagasRestantes']}\n\n'
          'Encontros:\n${item.meetings.map(_meetingDescription).join('\n')}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        if (organization)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancel(item);
            },
            child: const Text('Cancelar atividade'),
          ),
      ],
    ),
  );

  String _roomDescription(String id) {
    final room = _findRoom(id);
    return room == null ? id : '${room.name} (${room.capacity} lugares)';
  }

  Room? _findRoom(String id) {
    for (final value in availableRooms) {
      if (value['id'] == id) return Room(value);
    }
    return null;
  }

  String _meetingDescription(Map<String, dynamic> meeting) =>
      '${meeting['inicio']} - ${meeting['fim']}';
  Future<void> _cancel(Activity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar atividade?'),
        content: const Text('Essa ação é definitiva.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.client.cancel(item.id);
      _load();
    } on ApiFailure catch (e) {
      setState(() => error = e.code);
    } catch (_) {
      setState(() => error = 'Não foi possível conectar à API');
    }
  }

  Future<void> _showEditor([Activity? item]) async {
    if (item == null && availableRooms.isEmpty) {
      try {
        availableRooms = await widget.client.rooms();
      } on ApiFailure catch (e) {
        if (mounted) setState(() => error = e.code);
        return;
      }
    }
    final title = TextEditingController(text: item?.title ?? '');
    final slots = TextEditingController(text: item?.slots.toString() ?? '10');
    String selectedType = item?.type ?? 'palestra';
    String? selectedRoom =
        item?.roomId ??
        (availableRooms.isEmpty ? null : availableRooms.first['id'] as String);
    final date = TextEditingController(text: '2026-10-19');
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '10:00');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Nova atividade' : 'Editar atividade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            if (item != null)
              TextField(
                controller: slots,
                decoration: const InputDecoration(labelText: 'Vagas'),
                keyboardType: TextInputType.number,
              ),
            if (item == null)
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'palestra', child: Text('Palestra')),
                  DropdownMenuItem(
                    value: 'minicurso',
                    child: Text('Minicurso'),
                  ),
                ],
                onChanged: (value) => selectedType = value ?? 'palestra',
              ),
            if (item == null)
              DropdownButtonFormField<String>(
                initialValue: selectedRoom,
                decoration: const InputDecoration(labelText: 'Sala'),
                items: availableRooms
                    .map(
                      (room) => DropdownMenuItem<String>(
                        value: room['id'] as String,
                        child: Text('${room['nome']} (${room['capacidade']})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedRoom = value,
              ),
            if (item == null) ...[
              TextField(
                controller: date,
                decoration: const InputDecoration(
                  labelText: 'Data (AAAA-MM-DD)',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: const InputDecoration(
                        labelText: 'Início (HH:MM)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: const InputDecoration(
                        labelText: 'Fim (HH:MM)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (item == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Para minicurso, a API exige de 2 a 5 encontros.'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                if (item != null) {
                  await widget.client.update(item.id, {
                    'titulo': title.text,
                    'vagas': int.parse(slots.text),
                  });
                } else {
                  final inicio = '${date.text}T${start.text}:00-03:00';
                  final fim = '${date.text}T${end.text}:00-03:00';
                  final next = DateTime.parse(date.text)
                      .add(const Duration(days: 1));
                  final nextDate =
                      '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
                  await widget.client.create({
                    'titulo': title.text,
                    'tipo': selectedType,
                    'salaId': selectedRoom,
                    'vagas': int.parse(slots.text),
                    'encontros': [
                      {'inicio': inicio, 'fim': fim},
                      if (selectedType == 'minicurso')
                        {
                          'inicio': '${nextDate}T${start.text}:00-03:00',
                          'fim': '${nextDate}T${end.text}:00-03:00',
                        },
                    ],
                  });
                }
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              } on ApiFailure catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                setState(() => error = e.code);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                setState(() => error = 'DADOS_INVALIDOS');
              }
            },
            child: Text(item == null ? 'Salvar' : 'Atualizar'),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
          if (action != null)
            TextButton(
              onPressed: action,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    ),
  );
}
