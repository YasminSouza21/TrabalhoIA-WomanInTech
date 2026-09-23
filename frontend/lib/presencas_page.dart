import 'package:flutter/material.dart';

import 'api_client.dart';

class PresencasPage extends StatefulWidget {
  const PresencasPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<PresencasPage> createState() => _PresencasPageState();
}

class _PresencasPageState extends State<PresencasPage> {
  late String selectedUser;
  List<Map<String, dynamic>> activities = const [];
  String? meetingId;
  MeetingCode? code;
  List<Attendance> attendances = const [];
  String? error;
  bool loading = false;
  final qrCode = TextEditingController();
  final participantId = TextEditingController();
  final justification = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedUser = widget.client.user ?? 'p-carla';
    _load();
  }

  @override
  void dispose() {
    qrCode.dispose();
    participantId.dispose();
    justification.dispose();
    super.dispose();
  }

  AppUser get currentUser =>
      ApiClient.knownUsers.firstWhere((user) => user.id == selectedUser);
  bool get organization => currentUser.role == 'organizacao';

  List<Map<String, dynamic>> get meetings => [
    for (final activity in activities)
      for (final meeting in (activity['encontros'] as List? ?? const []))
        {
          'id': meeting['id'],
          'label': '${activity['titulo']} - ${meeting['inicio']}',
        },
  ];

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    widget.client.user = selectedUser;
    try {
      final loaded = await widget.client.activities();
      if (!mounted) return;
      setState(() {
        activities = loaded;
        meetingId ??= meetings.isEmpty ? null : meetings.first['id'] as String;
        loading = false;
      });
      if (organization && meetingId != null) await _loadAttendances();
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          error = e.code;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível conectar à API';
          loading = false;
        });
      }
    }
  }

  Future<void> _loadAttendances() async {
    if (!organization || meetingId == null) return;
    try {
      final loaded = await widget.client.attendances(meetingId!);
      if (mounted) setState(() => attendances = loaded);
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() => error = e.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível conectar à API');
      }
    }
  }

  Future<void> _getCode() async {
    if (meetingId == null) return;
    setState(() => loading = true);
    try {
      final loaded = await widget.client.meetingCode(meetingId!);
      if (mounted) {
        setState(() {
          code = loaded;
          loading = false;
          error = null;
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          error = e.code;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível conectar à API';
          loading = false;
        });
      }
    }
  }

  Future<void> _registerQr() async {
    if (meetingId == null) return;
    setState(() => loading = true);
    try {
      await widget.client.registerQr(meetingId!, qrCode.text.trim());
      if (mounted) {
        setState(() {
          loading = false;
          error = null;
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          error = e.code;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível conectar à API';
          loading = false;
        });
      }
    }
  }

  Future<void> _registerManual() async {
    if (meetingId == null) return;
    setState(() => loading = true);
    try {
      await widget.client.registerManual(
        meetingId!,
        participantId.text.trim(),
        justification.text,
      );
      if (mounted) {
        setState(() {
          loading = false;
          error = null;
        });
        await _loadAttendances();
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          error = e.code;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível conectar à API';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presenças')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              key: const ValueKey('presenca-usuario'),
              initialValue: selectedUser,
              decoration: const InputDecoration(labelText: 'Usuário'),
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
                setState(() {
                  selectedUser = value;
                  widget.client.user = value;
                  code = null;
                  attendances = const [];
                });
                _load();
              },
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error!, key: const ValueKey('presenca-erro')),
                ),
              ),
            if (!loading && meetings.isEmpty && error == null)
              const Text(
                'Nenhum encontro disponível.',
                key: ValueKey('presenca-vazio'),
              ),
            if (meetings.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('presenca-encontro'),
                initialValue: meetingId,
                decoration: const InputDecoration(labelText: 'Encontro'),
                items: meetings
                    .map(
                      (meeting) => DropdownMenuItem<String>(
                        value: meeting['id'] as String,
                        child: Text(meeting['label'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    meetingId = value;
                    code = null;
                  });
                  if (organization) await _loadAttendances();
                },
              ),
              const SizedBox(height: 16),
              if (organization) _organizationActions(),
              if (!organization) _participantActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _organizationActions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FilledButton(
        onPressed: loading ? null : _getCode,
        child: const Text('Obter QR'),
      ),
      if (code != null) ...[
        const SizedBox(height: 8),
        Text('Código: ${code!.code}', key: const ValueKey('presenca-codigo')),
        Text('Troca em: ${code!.changesAt}'),
        Text('Válido até: ${code!.validUntil}'),
      ],
      const Divider(height: 32),
      TextField(
        controller: participantId,
        decoration: const InputDecoration(labelText: 'Participante'),
      ),
      TextField(
        controller: justification,
        decoration: const InputDecoration(labelText: 'Justificativa'),
      ),
      FilledButton(
        onPressed: loading ? null : _registerManual,
        child: const Text('Registrar manual'),
      ),
      const SizedBox(height: 16),
      if (attendances.isEmpty)
        const Text(
          'Nenhuma presença registrada.',
          key: ValueKey('presenca-lista-vazia'),
        )
      else
        ...attendances.map(
          (item) => ListTile(
            title: Text(item.participantId),
            subtitle: Text(item.origin),
          ),
        ),
    ],
  );

  Widget _participantActions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: qrCode,
        decoration: const InputDecoration(labelText: 'Código do QR'),
      ),
      FilledButton(
        onPressed: loading ? null : _registerQr,
        child: const Text('Registrar presença'),
      ),
    ],
  );
}
