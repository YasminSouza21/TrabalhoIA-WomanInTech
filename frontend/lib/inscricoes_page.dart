import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';

class InscricoesPage extends StatefulWidget {
  const InscricoesPage({super.key, required this.client, this.clock});
  final ApiClient client;
  final DateTime Function()? clock;
  @override
  State<InscricoesPage> createState() => _InscricoesPageState();
}

class _InscricoesPageState extends State<InscricoesPage> {
  late String selectedUser;
  String selectedAtividadeId = '';
  List<Inscricao> inscricoes = const [];
  List<Map<String, dynamic>> atividades = const [];
  String? error;
  bool loading = false;
  int _generation = 0;
  Timer? _countdown;
  DateTime _clock = DateTime.now();
  String? _mutatingId;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    selectedUser = widget.client.user ?? 'p-carla';
    _load();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  AppUser get currentUser =>
      ApiClient.knownUsers.firstWhere((user) => user.id == selectedUser);
  bool get organization => currentUser.role == 'organizacao';

  Future<void> _load() async {
    final generation = ++_generation;
    final user = selectedUser;
    final organizacao = organization;
    final filtro = selectedAtividadeId;
    setState(() {
      loading = true;
      error = null;
    });
    widget.client.user = user;
    try {
      final atvs = await widget.client.activities();
      if (!mounted || generation != _generation) return;
      final listadas = await widget.client.listarInscricoes(
        atividadeId: organizacao ? filtro : null,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        atividades = atvs;
        inscricoes = listadas;
        error = null;
        loading = false;
      });
      _restartCountdown();
    } on ApiFailure catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        error = e.code;
        loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        error = 'Não foi possível conectar à API';
        loading = false;
      });
    }
  }

  void _restartCountdown() {
    _countdown?.cancel();
    final hasConvocada = inscricoes.any(
      (ins) => ins.status == 'convocada' && ins.convocadaAte != null,
    );
    if (!hasConvocada) return;
    _clock = _now();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _clock = _now());
    });
  }

  String get _emptyMessage =>
      organization
      ? 'Nenhuma inscrição encontrada.'
      : 'Você ainda não tem inscrições.';

  void _selectUser(String? value) {
    if (value == null || value == selectedUser) return;
    _countdown?.cancel();
    setState(() {
      selectedUser = value;
      inscricoes = const [];
      atividades = const [];
      selectedAtividadeId = '';
      error = null;
    });
    _load();
  }

  Widget _seletorUsuario() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Text('Usuário:'),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              key: const ValueKey('seletor-usuario'),
              value: selectedUser,
              isExpanded: true,
              isDense: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: ApiClient.knownUsers
                  .map(
                    (user) => DropdownMenuItem(
                      value: user.id,
                      child: Text('${user.name} (${user.role})'),
                    ),
                  )
                  .toList(),
              onChanged: _selectUser,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroAtividade() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Text('Atividade:'),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              key: const ValueKey('filtro-atividade'),
              value: selectedAtividadeId,
              isExpanded: true,
              isDense: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('Todas')),
                ...atividades.map(
                  (atividade) => DropdownMenuItem(
                    value: atividade['id'] as String,
                    child: Text(atividade['titulo'] as String),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                selectedAtividadeId = value;
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(organization ? 'Inscrições' : 'Minhas inscrições'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _seletorUsuario(),
            if (organization) _filtroAtividade(),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!loading && error != null)
              _MessageState(icon: Icons.error_outline, text: error!, action: _load),
            if (!loading && error == null && inscricoes.isEmpty)
              _MessageState(
                icon: Icons.event_busy,
                text: _emptyMessage,
              ),
            if (!loading && error == null && inscricoes.isNotEmpty)
              ...inscricoes.map(_card),
          ],
        ),
      ),
    );
  }

  Widget _card(Inscricao inscricao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleOf(inscricao.atividadeId),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(inscricao.status),
            if (inscricao.status == 'em_espera' &&
                inscricao.posicaoNaEspera != null)
              Text('Posição na espera: ${inscricao.posicaoNaEspera}'),
            if (inscricao.status == 'convocada' &&
                inscricao.convocadaAte != null)
              _convocacaoPrazo(inscricao),
            if (!organization &&
                (inscricao.status == 'confirmada' ||
                    inscricao.status == 'em_espera' ||
                    inscricao.status == 'convocada'))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _mutatingId == null
                      ? () => _cancelarInscricao(inscricao)
                      : null,
                  child: const Text('Cancelar'),
                ),
              ),
            if (!organization && inscricao.status == 'convocada')
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _mutatingId == null
                      ? () => _confirmarConvocacao(inscricao)
                      : null,
                  child: const Text('Confirmar convocação'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarInscricao(Inscricao inscricao) =>
      _mutar(inscricao, () => widget.client.cancelarInscricao(inscricao.id),
          'Inscrição cancelada.');

  Future<void> _confirmarConvocacao(Inscricao inscricao) => _mutar(
      inscricao, () => widget.client.confirmarConvocacao(inscricao.id),
      'Inscrição confirmada.');

  Future<void> _mutar(
    Inscricao inscricao,
    Future<Inscricao> Function() operacao,
    String feedback,
  ) async {
    setState(() => _mutatingId = inscricao.id);
    widget.client.user = selectedUser;
    try {
      await operacao();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(feedback)));
      await _load();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => error = e.code);
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível conectar à API');
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Widget _convocacaoPrazo(Inscricao inscricao) {
    final deadline = DateTime.parse(inscricao.convocadaAte!).toLocal();
    final restam = deadline.difference(_clock);
    return Text(
      'Convocado até ${_formatPrazo(deadline)} (Restam ${_formatRestam(restam)})',
    );
  }

  String _formatPrazo(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final minuto = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$minuto';
  }

  String _formatRestam(Duration restam) {
    final d = restam.isNegative ? Duration.zero : restam;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _titleOf(String atividadeId) {
    for (final json in atividades) {
      if (json['id'] == atividadeId) return json['titulo'] as String;
    }
    return atividadeId;
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.text, this.action});
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