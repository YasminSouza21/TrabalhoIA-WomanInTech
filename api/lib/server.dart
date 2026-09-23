import 'dart:convert';
import 'dart:io';
import 'dart:math';

class User {
  User(this.id, this.name, this.role);
  final String id;
  final String name;
  final String role;
}

class Room {
  Room(this.id, this.name, this.capacity);
  final String id;
  final String name;
  final int capacity;
  Map<String, Object> toJson() =>
      {'id': id, 'nome': name, 'capacidade': capacity};
}

class Meeting {
  Meeting(this.id, this.start, this.end);
  final String id;
  final DateTime start;
  final DateTime end;
}

class Enrollment {
  Enrollment({
    required this.id,
    required this.activityId,
    required this.participantId,
    required this.status,
    required this.sequenceNumber,
    required this.createdAt,
    this.convocationDeadline,
    this.expiryCause,
  });
  final String id;
  final String activityId;
  final String participantId;
  String status;
  final int sequenceNumber;
  final DateTime createdAt;
  DateTime? convocationDeadline;
  String? expiryCause;
}

class Attendance {
  Attendance({
    required this.id,
    required this.meetingId,
    required this.participantId,
    required this.origin,
    required this.readAt,
    required this.recordedAt,
    this.justification,
    this.manualOrganizationId,
  });
  final String id;
  final String meetingId;
  final String participantId;
  final String origin;
  final DateTime readAt;
  final DateTime recordedAt;
  final String? justification;
  final String? manualOrganizationId;
}

class Activity {
  Activity(
      {required this.id,
      required this.title,
      required this.type,
      required this.roomId,
      required this.slots,
      required this.meetings});
  final String id;
  String title;
  final String type;
  final String roomId;
  int slots;
  final List<Meeting> meetings;
  bool cancelled = false;
}

class ApiError {
  ApiError(this.code, [this.message]);
  final String code;
  final String? message;
  Map<String, String> toJson() => {'erro': code, 'mensagem': message ?? code};
}

DateTime _brasilia(DateTime instant) =>
    instant.toUtc().subtract(const Duration(hours: 3));
DateTime _parseDate(Object? value) => DateTime.parse(value as String).toUtc();
String _formatDate(DateTime value) =>
    value.toUtc().toIso8601String().replaceFirst(RegExp(r'\.000Z$'), 'Z');
String _id(String prefix) =>
    '$prefix${Random().nextInt(0x100000000).toRadixString(16).padLeft(8, '0')}';

class ApiServer {
  ApiServer(
      {this.modoTeste = false,
      String? stateFile,
      DateTime Function()? clockProvider})
      : _stateFilePath = stateFile ?? 'data/estado.json' {
    _clockProvider = clockProvider ?? DateTime.now;
    if (modoTeste) {
      reset();
    } else {
      _load();
    }
  }
  final bool modoTeste;
  final String _stateFilePath;
  late final DateTime Function() _clockProvider;
  bool _dirty = false;
  final users = <String, User>{};
  final rooms = <String, Room>{};
  final activities = <String, Activity>{};
  final enrollments = <Enrollment>[];
  final attendances = <Attendance>[];
  late DateTime clock;
  int _enrollmentSequence = 0;
  int _attendanceSequence = 0;

  void reset() {
    _dirty = false;
    clock =
        modoTeste ? DateTime.utc(2026, 10, 13, 12) : _clockProvider().toUtc();
    _enrollmentSequence = 0;
    _attendanceSequence = 0;
    users
      ..clear()
      ..addAll({
        'org-ana': User('org-ana', 'Ana Beatriz Lima', 'organizacao'),
        'org-bruno': User('org-bruno', 'Bruno Tavares', 'organizacao'),
        'p-carla': User('p-carla', 'Carla Mendes Souza', 'participante'),
        'p-diego': User('p-diego', 'Diego Alves', 'participante'),
        'p-elisa': User('p-elisa', 'Elisa Fernandes da Rocha', 'participante'),
        'p-fabio': User('p-fabio', 'Fábio Nogueira', 'participante'),
        'p-gabriela':
            User('p-gabriela', 'Gabriela Moura Castro', 'participante'),
        'p-heitor': User('p-heitor', 'Heitor Campos', 'participante'),
        'p-isadora':
            User('p-isadora', 'Isadora Ribeiro dos Santos', 'participante'),
        'p-joao': User('p-joao', 'João Pedro Martins', 'participante'),
      });
    rooms
      ..clear()
      ..addAll({
        'auditorio': Room('auditorio', 'Auditório Central', 200),
        'sala-101': Room('sala-101', 'Sala 101', 40),
        'sala-102': Room('sala-102', 'Sala 102', 40),
        'lab-3': Room('lab-3', 'Laboratório 3', 20),
      });
    activities.clear();
    enrollments.clear();
    attendances.clear();
  }

  void _load() {
    reset();
    final file = File(_stateFilePath);
    if (!file.existsSync()) return;
    Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } catch (_) {
      throw StateError(
          'Arquivo de estado corrompido ($_stateFilePath): falha ao decodificar JSON.');
    }
    if (decoded is! Map ||
        decoded['atividades'] is! List ||
        decoded['inscricoes'] is! List ||
        decoded['sequencia'] is! int) {
      throw StateError(
          'Arquivo de estado invalido ($_stateFilePath): campos esperados ausentes.');
    }
    final sequencia = decoded['sequencia'] as int;
    if (sequencia < 0) {
      throw StateError(
          'Arquivo de estado invalido ($_stateFilePath): sequencia negativa.');
    }
    try {
      for (final raw in decoded['atividades'] as List) {
        final atividade = _activityFromJson(raw);
        activities[atividade.id] = atividade;
      }
      var maxSequencia = sequencia;
      for (final raw in decoded['inscricoes'] as List) {
        final inscricao = _inscricaoFromJson(raw);
        if (inscricao.sequenceNumber > maxSequencia) {
          maxSequencia = inscricao.sequenceNumber;
        }
        enrollments.add(inscricao);
      }
      final rawAttendances = decoded['presencas'];
      if (rawAttendances is List) {
        for (final raw in rawAttendances) {
          attendances.add(_attendanceFromJson(raw));
        }
      }
      final sequenciaPresencas = decoded['sequenciaPresencas'];
      if (sequenciaPresencas is int && sequenciaPresencas >= 0) {
        _attendanceSequence = sequenciaPresencas;
      }
      _enrollmentSequence = maxSequencia;
    } catch (error) {
      throw StateError('Arquivo de estado invalido ($_stateFilePath): $error');
    }
  }

  Activity _activityFromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['titulo'] is! String ||
        raw['tipo'] is! String ||
        raw['salaId'] is! String ||
        raw['vagas'] is! int ||
        raw['encontros'] is! List) {
      throw const FormatException('atividade mal formada');
    }
    final encontros = <Meeting>[];
    for (final found in raw['encontros'] as List) {
      if (found is! Map ||
          found['id'] is! String ||
          found['inicio'] is! String ||
          found['fim'] is! String) {
        throw const FormatException('encontro mal formado');
      }
      encontros.add(Meeting(found['id'] as String, _parseDate(found['inicio']),
          _parseDate(found['fim'])));
    }
    if (encontros.isEmpty) {
      throw const FormatException('atividade sem encontros');
    }
    return Activity(
        id: raw['id'] as String,
        title: raw['titulo'] as String,
        type: raw['tipo'] as String,
        roomId: raw['salaId'] as String,
        slots: raw['vagas'] as int,
        meetings: encontros)
      ..cancelled = raw['cancelada'] == true;
  }

  Enrollment _inscricaoFromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['atividadeId'] is! String ||
        raw['participanteId'] is! String ||
        raw['status'] is! String ||
        raw['sequenceNumber'] is! int ||
        raw['createdAt'] is! String) {
      throw const FormatException('inscricao mal formada');
    }
    final convocadaAte = raw['convocadaAte'];
    final expiryCause = raw['expiryCause'];
    if ((convocadaAte != null && convocadaAte is! String) ||
        (expiryCause != null && expiryCause is! String)) {
      throw const FormatException('inscricao mal formada');
    }
    final atividadeId = raw['atividadeId'] as String;
    if (activities[atividadeId] == null) {
      throw FormatException(
          'inscricao referencia atividade inexistente ($atividadeId)');
    }
    return Enrollment(
        id: raw['id'] as String,
        activityId: atividadeId,
        participantId: raw['participanteId'] as String,
        status: raw['status'] as String,
        sequenceNumber: raw['sequenceNumber'] as int,
        createdAt: _parseDate(raw['createdAt'] as String),
        convocationDeadline:
            convocadaAte is String ? _parseDate(convocadaAte) : null,
        expiryCause: expiryCause as String?);
  }

  Attendance _attendanceFromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['encontroId'] is! String ||
        raw['participanteId'] is! String ||
        raw['origem'] is! String ||
        raw['lidoEm'] is! String ||
        raw['registradaEm'] is! String) {
      throw const FormatException('presenca mal formada');
    }
    final justificativa = raw['justificativa'];
    final organizacao = raw['organizacaoId'];
    if ((justificativa != null && justificativa is! String) ||
        (organizacao != null && organizacao is! String)) {
      throw const FormatException('presenca mal formada');
    }
    return Attendance(
      id: raw['id'] as String,
      meetingId: raw['encontroId'] as String,
      participantId: raw['participanteId'] as String,
      origin: raw['origem'] as String,
      readAt: _parseDate(raw['lidoEm']),
      recordedAt: _parseDate(raw['registradaEm']),
      justification: justificativa as String?,
      manualOrganizationId: organizacao as String?,
    );
  }

  void _persist() {
    if (modoTeste) return;
    final target = File(_stateFilePath);
    target.parent.createSync(recursive: true);
    final temp = File('$_stateFilePath.tmp');
    temp.writeAsStringSync(jsonEncode(_stateToJson()), flush: true);
    temp.renameSync(_stateFilePath);
  }

  Future<void> _commit() async {
    if (!_dirty) return;
    _persist();
    _dirty = false;
  }

  Future<void> _refreshClockAndReconcile() async {
    if (!modoTeste) clock = _clockProvider().toUtc();
    _reconcile();
    if (_dirty) await _commit();
  }

  Map<String, Object?> _stateToJson() => {
        'atividades': activities.values
            .map((atividade) => {
                  'id': atividade.id,
                  'titulo': atividade.title,
                  'tipo': atividade.type,
                  'salaId': atividade.roomId,
                  'vagas': atividade.slots,
                  'cancelada': atividade.cancelled,
                  'encontros': atividade.meetings
                      .map((encontro) => {
                            'id': encontro.id,
                            'inicio': _formatDate(encontro.start),
                            'fim': _formatDate(encontro.end)
                          })
                      .toList(),
                })
            .toList(),
        'inscricoes': enrollments
            .map((enrollment) => {
                  'id': enrollment.id,
                  'atividadeId': enrollment.activityId,
                  'participanteId': enrollment.participantId,
                  'status': enrollment.status,
                  'sequenceNumber': enrollment.sequenceNumber,
                  'createdAt': _formatDate(enrollment.createdAt),
                  'convocadaAte': enrollment.convocationDeadline != null
                      ? _formatDate(enrollment.convocationDeadline!)
                      : null,
                  'expiryCause': enrollment.expiryCause,
                })
            .toList(),
        'sequencia': _enrollmentSequence,
        'presencas': attendances
            .map((attendance) => {
                  'id': attendance.id,
                  'encontroId': attendance.meetingId,
                  'participanteId': attendance.participantId,
                  'origem': attendance.origin,
                  'lidoEm': _formatDate(attendance.readAt),
                  'registradaEm': _formatDate(attendance.recordedAt),
                  'justificativa': attendance.justification,
                  'organizacaoId': attendance.manualOrganizationId,
                })
            .toList(),
        'sequenciaPresencas': _attendanceSequence,
      };

  Future<void> handle(HttpRequest request) async {
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Headers', 'Content-Type, X-Usuario')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, OPTIONS');
    if (request.method == 'OPTIONS') return _finish(request, 204);
    try {
      if (!modoTeste) clock = _clockProvider().toUtc();
      final path = request.uri.path;
      if (path.startsWith('/_teste/')) return await _testRoute(request);
      _reconcile();
      if (_dirty) await _commit();
      if (path == '/salas') return await _roomsRoute(request);
      if (path == '/atividades') return await _activitiesRoute(request);
      if (path.startsWith('/atividades/')) return await _activityRoute(request);
      if (path == '/inscricoes') return await _inscricoesRoute(request);
      if (path.startsWith('/inscricoes/'))
        return await _inscricaoRoute(request);
      if (path.startsWith('/encontros/')) return await _meetingRoute(request);
      _finish(request, 404);
    } catch (_) {
      _json(request, 500, ApiError('ERRO_INTERNO').toJson());
    }
  }

  Future<void> _testRoute(HttpRequest request) async {
    if (!modoTeste) return _finish(request, 404);
    if (request.uri.path == '/_teste/reset' && request.method == 'POST') {
      reset();
      return _finish(request, 204);
    }
    if (request.uri.path != '/_teste/relogio') return _finish(request, 404);
    if (request.method == 'GET')
      return _json(request, 200, {'agora': _formatDate(clock)});
    if (request.method != 'PUT') return _finish(request, 405);
    final body = await _body(request);
    if (body is! Map || body['agora'] is! String)
      return _error(request, 422, 'DADOS_INVALIDOS');
    try {
      clock = _parseDate(body['agora']);
      _reconcile();
      return _json(request, 200, {'agora': _formatDate(clock)});
    } catch (_) {
      return _error(request, 422, 'DADOS_INVALIDOS');
    }
  }

  User? _user(HttpRequest request, {String? role}) {
    final user = users[request.headers.value('X-Usuario')];
    if (user == null) return null;
    if (role != null && user.role != role)
      return User('', '__forbidden__', 'forbidden');
    return user;
  }

  bool _authorized(HttpRequest request, String? role,
      {String roleError = 'SOMENTE_ORGANIZACAO'}) {
    final user = _user(request, role: role);
    if (user == null) {
      _error(request, 401, 'USUARIO_DESCONHECIDO');
      return false;
    }
    if (user.role == 'forbidden') {
      _error(request, 403, roleError);
      return false;
    }
    return true;
  }

  Future<void> _roomsRoute(HttpRequest request) async {
    if (request.method != 'GET') return _finish(request, 405);
    if (!_authorized(request, null)) return;
    final result = rooms.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    _json(request, 200, result.map((room) => room.toJson()).toList());
  }

  Future<void> _activitiesRoute(HttpRequest request) async {
    if (request.method == 'GET') return _list(request);
    if (request.method == 'POST') return _create(request);
    _finish(request, 405);
  }

  Future<void> _activityRoute(HttpRequest request) async {
    final parts =
        request.uri.path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 2 || parts.length > 3) return _finish(request, 404);
    final id = parts[1];
    if (parts.length == 3 && parts[2] == 'inscricoes')
      return _inscricaoCreateRoute(request, id);
    if (activities[id] == null) {
      if (!_authorized(request, request.method == 'GET' ? null : 'organizacao'))
        return;
      return _error(request, 404, 'NAO_ENCONTRADO');
    }
    if (parts.length == 3 &&
        parts[2] == 'cancelamento' &&
        request.method == 'POST') return _cancel(request, id);
    if (parts.length != 2) return _finish(request, 404);
    if (request.method == 'GET') return _detail(request, id);
    if (request.method == 'PATCH') return _patch(request, id);
    _finish(request, 405);
  }

  Future<void> _meetingRoute(HttpRequest request) async {
    final parts =
        request.uri.path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 3 || parts.length > 4) return _finish(request, 404);
    final meetingId = parts[1];
    final context = _meetingContext(meetingId);
    if (parts[2] == 'codigo' && request.method == 'GET') {
      if (!_authorized(request, 'organizacao')) return;
      if (context == null) return _error(request, 404, 'NAO_ENCONTRADO');
      return _meetingCode(request, context.activity, context.meeting);
    }
    if (parts[2] == 'presencas' && request.method == 'GET') {
      if (!_authorized(request, 'organizacao')) return;
      if (context == null) return _error(request, 404, 'NAO_ENCONTRADO');
      return _listAttendances(request, meetingId);
    }
    if (parts[2] == 'presencas' &&
        parts.length == 3 &&
        request.method == 'POST') {
      return _registerQr(request, context);
    }
    if (parts[2] == 'presencas' &&
        parts.length == 4 &&
        parts[3] == 'manual' &&
        request.method == 'POST') {
      return _registerManual(request, context);
    }
    return _finish(request, 404);
  }

  ({Activity activity, Meeting meeting})? _meetingContext(String id) {
    for (final activity in activities.values) {
      for (final meeting in activity.meetings) {
        if (meeting.id == id) return (activity: activity, meeting: meeting);
      }
    }
    return null;
  }

  DateTime _windowStart(Meeting meeting) =>
      meeting.start.subtract(const Duration(minutes: 15));
  DateTime _windowEnd(Meeting meeting) =>
      meeting.end.add(const Duration(minutes: 15));

  bool _inWindow(DateTime instant, Meeting meeting) =>
      !instant.isBefore(_windowStart(meeting)) &&
      !instant.isAfter(_windowEnd(meeting));

  int _codeBucket(DateTime instant, Meeting meeting) =>
      instant.difference(_windowStart(meeting)).inMinutes ~/ 5;

  String _meetingCodeValue(Meeting meeting, int bucket) {
    var value = 2166136261;
    for (final byte in utf8.encode('${meeting.id}:$bucket')) {
      value = ((value ^ byte) * 16777619) & 0xffffffff;
    }
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final result = StringBuffer();
    for (var index = 0; index < 6; index++) {
      result.write(alphabet[(value >> (index * 5)) & 31]);
    }
    return result.toString();
  }

  Future<void> _meetingCode(
      HttpRequest request, Activity activity, Meeting meeting) async {
    if (activity.cancelled) {
      return _error(request, 422, 'ATIVIDADE_CANCELADA');
    }
    if (!_inWindow(clock, meeting)) {
      return _error(request, 422, 'FORA_DA_JANELA');
    }
    final bucket = _codeBucket(clock, meeting);
    final troca =
        _windowStart(meeting).add(Duration(minutes: (bucket + 1) * 5));
    return _json(request, 200, {
      'encontroId': meeting.id,
      'codigo': _meetingCodeValue(meeting, bucket),
      'trocaEm': _formatDate(troca),
      'validoAte': _formatDate(troca),
    });
  }

  Attendance? _attendanceFor(String meetingId, String participantId) {
    for (final attendance in attendances) {
      if (attendance.meetingId == meetingId &&
          attendance.participantId == participantId) return attendance;
    }
    return null;
  }

  Enrollment? _confirmedEnrollment(String activityId, String participantId) {
    for (final enrollment in enrollments) {
      if (enrollment.activityId == activityId &&
          enrollment.participantId == participantId &&
          enrollment.status == 'confirmada') return enrollment;
    }
    return null;
  }

  Future<void> _registerQr(HttpRequest request,
      ({Activity activity, Meeting meeting})? context) async {
    if (!_authorized(request, 'participante',
        roleError: 'SOMENTE_PARTICIPANTE')) {
      return;
    }
    if (context == null) return _error(request, 404, 'NAO_ENCONTRADO');
    final body = await _body(request);
    if (body is! Map || body['codigo'] is! String) {
      return _error(request, 422, 'DADOS_INVALIDOS');
    }
    final participant = _user(request)!;
    if (context.activity.cancelled) {
      return _error(request, 422, 'ATIVIDADE_CANCELADA');
    }
    final duplicate = _attendanceFor(context.meeting.id, participant.id);
    if (duplicate != null)
      return _json(request, 200, _attendanceJson(duplicate));
    if (_confirmedEnrollment(context.activity.id, participant.id) == null) {
      return _error(request, 403, 'NAO_INSCRITO');
    }
    final readAt =
        body['lidoEm'] == null ? clock : _parseOptionalDate(body['lidoEm']);
    if (readAt == null) return _error(request, 422, 'DADOS_INVALIDOS');
    if (body['lidoEm'] != null &&
        (readAt.isAfter(clock) ||
            clock.difference(readAt).abs() > const Duration(minutes: 10))) {
      return _error(request, 422, 'SINCRONIZACAO_TARDIA');
    }
    if (!_inWindow(readAt, context.meeting)) {
      return _error(request, 422, 'FORA_DA_JANELA');
    }
    final bucket = _codeBucket(readAt, context.meeting);
    if (body['codigo'] != _meetingCodeValue(context.meeting, bucket)) {
      return _error(request, 422, 'CODIGO_INVALIDO');
    }
    final attendance = Attendance(
      id: _id('pre_'),
      meetingId: context.meeting.id,
      participantId: participant.id,
      origin: body['lidoEm'] == null ? 'qr' : 'qr_offline',
      readAt: readAt,
      recordedAt: clock,
    );
    attendances.add(attendance);
    _attendanceSequence++;
    _dirty = true;
    await _commit();
    return _json(request, 201, _attendanceJson(attendance));
  }

  DateTime? _parseOptionalDate(Object? value) {
    if (value is! String) return null;
    try {
      return _parseDate(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerManual(HttpRequest request,
      ({Activity activity, Meeting meeting})? context) async {
    if (!_authorized(request, 'organizacao')) return;
    if (context == null) return _error(request, 404, 'NAO_ENCONTRADO');
    final body = await _body(request);
    if (body is! Map || body['participanteId'] is! String) {
      return _error(request, 422, 'DADOS_INVALIDOS');
    }
    final participantId = body['participanteId'] as String;
    if (context.activity.cancelled) {
      return _error(request, 422, 'ATIVIDADE_CANCELADA');
    }
    final duplicate = _attendanceFor(context.meeting.id, participantId);
    if (duplicate != null)
      return _json(request, 200, _attendanceJson(duplicate));
    if (_confirmedEnrollment(context.activity.id, participantId) == null) {
      return _error(request, 403, 'NAO_INSCRITO');
    }
    if (!body.containsKey('justificativa')) {
      return _error(request, 422, 'JUSTIFICATIVA_OBRIGATORIA');
    }
    if (body['justificativa'] is! String) {
      return _error(request, 422, 'DADOS_INVALIDOS');
    }
    final justification = (body['justificativa'] as String).trim();
    if (justification.length < 10 || justification.length > 500) {
      return _error(request, 422, 'JUSTIFICATIVA_OBRIGATORIA');
    }
    if (!_inWindow(clock, context.meeting)) {
      return _error(request, 422, 'FORA_DA_JANELA');
    }
    final attendance = Attendance(
      id: _id('pre_'),
      meetingId: context.meeting.id,
      participantId: participantId,
      origin: 'manual',
      readAt: clock,
      recordedAt: clock,
      justification: justification,
      manualOrganizationId: _user(request)!.id,
    );
    attendances.add(attendance);
    _attendanceSequence++;
    _dirty = true;
    await _commit();
    return _json(request, 201, _attendanceJson(attendance));
  }

  Future<void> _listAttendances(HttpRequest request, String meetingId) async {
    final result = attendances
        .where((item) => item.meetingId == meetingId)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return _json(request, 200, result.map(_attendanceJson).toList());
  }

  Map<String, Object?> _attendanceJson(Attendance attendance) => {
        'id': attendance.id,
        'encontroId': attendance.meetingId,
        'participanteId': attendance.participantId,
        'origem': attendance.origin,
        'lidoEm': _formatDate(attendance.readAt),
        'registradaEm': _formatDate(attendance.recordedAt),
        'justificativa': attendance.justification,
      };

  Future<void> _create(HttpRequest request) async {
    if (!_authorized(request, 'organizacao')) return;
    final body = await _body(request);
    if (body is! Map ||
        body['titulo'] is! String ||
        body['tipo'] is! String ||
        body['salaId'] is! String ||
        body['vagas'] is! int ||
        body['encontros'] is! List)
      return _error(request, 422, 'DADOS_INVALIDOS');
    final meetings = _meetings(body['encontros'], createIds: true);
    if (meetings == null) return _error(request, 422, 'DADOS_INVALIDOS');
    final activity = Activity(
        id: _id('atv_'),
        title: body['titulo'] as String,
        type: body['tipo'] as String,
        roomId: body['salaId'] as String,
        slots: body['vagas'] as int,
        meetings: meetings);
    final validation = _validateCreate(activity);
    if (validation != null)
      return _error(
          request, validation == 'CONFLITO_DE_SALA' ? 409 : 422, validation);
    activities[activity.id] = activity;
    _dirty = true;
    await _commit();
    _json(request, 201, _activityJson(activity));
  }

  List<Meeting>? _meetings(Object value, {required bool createIds}) {
    final list = value as List;
    try {
      return list.map((raw) {
        if (raw is! Map || raw['inicio'] is! String || raw['fim'] is! String)
          throw const FormatException();
        return Meeting(createIds ? _id('enc_') : '', _parseDate(raw['inicio']),
            _parseDate(raw['fim']));
      }).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    } catch (_) {
      return null;
    }
  }

  String? _validateCreate(Activity activity) {
    if (activity.type != 'palestra' && activity.type != 'minicurso')
      return 'DADOS_INVALIDOS';
    if ((activity.type == 'palestra' && activity.meetings.length != 1) ||
        (activity.type == 'minicurso' &&
            (activity.meetings.length < 2 || activity.meetings.length > 5)))
      return 'QUANTIDADE_DE_ENCONTROS';
    if (!_validMeetings(activity.meetings)) return 'ENCONTRO_INVALIDO';
    final room = rooms[activity.roomId];
    if (room == null) return 'DADOS_INVALIDOS';
    if (activity.slots < 1) return 'DADOS_INVALIDOS';
    if (activity.slots > room.capacity) return 'VAGAS_ACIMA_DA_CAPACIDADE';
    if (_roomConflict(activity)) return 'CONFLITO_DE_SALA';
    return null;
  }

  bool _validMeetings(List<Meeting> meetings) {
    for (var i = 0; i < meetings.length; i++) {
      final meeting = meetings[i];
      final start = _brasilia(meeting.start), end = _brasilia(meeting.end);
      if (start.year != 2026 ||
          start.month != 10 ||
          start.day < 19 ||
          start.day > 23 ||
          end.year != 2026 ||
          end.month != 10 ||
          end.day < 19 ||
          end.day > 23) return false;
      if (start.year != end.year ||
          start.month != end.month ||
          start.day != end.day) return false;
      final duration = meeting.end.difference(meeting.start);
      if (duration < const Duration(hours: 1) ||
          duration > const Duration(hours: 4)) return false;
      if (i > 0 && meetings[i - 1].end.isAfter(meeting.start)) return false;
    }
    return true;
  }

  bool _roomConflict(Activity candidate) {
    for (final existing in activities.values) {
      if (existing.cancelled || existing.roomId != candidate.roomId) continue;
      for (final a in existing.meetings)
        for (final b in candidate.meetings) {
          final overlap = a.start.isBefore(b.end) && b.start.isBefore(a.end);
          final closeBefore = !a.end.isAfter(b.start) &&
              b.start.difference(a.end) < const Duration(minutes: 15);
          final closeAfter = !b.end.isAfter(a.start) &&
              a.start.difference(b.end) < const Duration(minutes: 15);
          if (overlap || closeBefore || closeAfter) return true;
        }
    }
    return false;
  }

  Future<void> _list(HttpRequest request) async {
    if (!_authorized(request, null)) return;
    final type = request.uri.queryParameters['tipo'];
    final day = request.uri.queryParameters['dia'];
    final result = activities.values.where((activity) {
      if (type != null && type.isNotEmpty && activity.type != type)
        return false;
      if (day != null &&
          day.isNotEmpty &&
          !activity.meetings.any((meeting) =>
              _brasilia(meeting.start).toIso8601String().startsWith(day)))
        return false;
      return true;
    }).toList();
    result.sort((a, b) {
      final compare = a.meetings.first.start.compareTo(b.meetings.first.start);
      return compare == 0 ? a.title.compareTo(b.title) : compare;
    });
    _json(request, 200, result.map(_activityJson).toList());
  }

  Future<void> _detail(HttpRequest request, String id) async {
    if (!_authorized(request, null)) return;
    _json(request, 200, _activityJson(activities[id]!));
  }

  Future<void> _patch(HttpRequest request, String id) async {
    if (!_authorized(request, 'organizacao')) return;
    final activity = activities[id]!;
    final body = await _body(request);
    if (body is! Map) return _error(request, 422, 'DADOS_INVALIDOS');
    if (body.containsKey('salaId') ||
        body.containsKey('tipo') ||
        body.containsKey('encontros'))
      return _error(request, 422, 'CAMPO_NAO_EDITAVEL');
    if (activity.cancelled) return _error(request, 422, 'ATIVIDADE_CANCELADA');
    if (body.containsKey('titulo') && body['titulo'] is! String ||
        body.containsKey('vagas') && body['vagas'] is! int)
      return _error(request, 422, 'DADOS_INVALIDOS');
    var nextTitle = activity.title;
    var nextSlots = activity.slots;
    if (body.containsKey('titulo')) nextTitle = body['titulo'] as String;
    if (body.containsKey('vagas')) {
      final slots = body['vagas'] as int;
      if (slots < 1) return _error(request, 422, 'DADOS_INVALIDOS');
      if (slots > rooms[activity.roomId]!.capacity)
        return _error(request, 422, 'VAGAS_ACIMA_DA_CAPACIDADE');
      if (slots < _occupied(activity.id))
        return _error(request, 409, 'VAGAS_ABAIXO_DOS_INSCRITOS');
      nextSlots = slots;
    }
    activity.title = nextTitle;
    activity.slots = nextSlots;
    _promote(id);
    _dirty = true;
    await _commit();
    _json(request, 200, _activityJson(activity));
  }

  Future<void> _cancel(HttpRequest request, String id) async {
    if (!_authorized(request, 'organizacao')) return;
    final activity = activities[id]!;
    if (activity.cancelled) return _error(request, 422, 'ATIVIDADE_CANCELADA');
    if (!clock.isBefore(activity.meetings.first.start))
      return _error(request, 422, 'ATIVIDADE_JA_INICIADA');
    activity.cancelled = true;
    for (final enrollment in enrollments) {
      if (enrollment.activityId != activity.id) continue;
      if (enrollment.status == 'expirada') continue;
      enrollment.status = 'cancelada';
      enrollment.convocationDeadline = null;
    }
    _dirty = true;
    await _commit();
    _json(request, 200, _activityJson(activity));
  }

  int _occupied(String id) => enrollments
      .where((e) =>
          e.activityId == id &&
          (e.status == 'confirmada' || e.status == 'convocada'))
      .length;
  int _waiting(String id) => enrollments
      .where((e) => e.activityId == id && e.status == 'em_espera')
      .length;
  Map<String, Object> _activityJson(Activity activity) {
    final meetings = [...activity.meetings]
      ..sort((a, b) => a.start.compareTo(b.start));
    final situation = activity.cancelled
        ? 'cancelada'
        : clock.isBefore(meetings.first.start)
            ? 'prevista'
            : !clock.isBefore(meetings.last.end)
                ? 'encerrada'
                : 'em_andamento';
    return {
      'id': activity.id,
      'titulo': activity.title,
      'tipo': activity.type,
      'salaId': activity.roomId,
      'vagas': activity.slots,
      'encontros': meetings
          .map((m) => {
                'id': m.id,
                'inicio': _formatDate(m.start),
                'fim': _formatDate(m.end)
              })
          .toList(),
      'cargaHorariaMinutos': meetings.fold<int>(
          0, (sum, m) => sum + m.end.difference(m.start).inMinutes),
      'situacao': situation,
      'ocupadas': _occupied(activity.id),
      'vagasRestantes': activity.slots - _occupied(activity.id),
      'emEspera': _waiting(activity.id)
    };
  }

  Future<void> _inscricoesRoute(HttpRequest request) async {
    if (request.method != 'GET') return _finish(request, 405);
    if (!_authorized(request, null)) return;
    final user = _user(request)!;
    final atividadeId = request.uri.queryParameters['atividadeId'];
    final result = enrollments
        .where((e) =>
            (user.role == 'organizacao' || e.participantId == user.id) &&
            (atividadeId == null ||
                atividadeId.isEmpty ||
                e.activityId == atividadeId))
        .toList()
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    _json(request, 200, result.map(_inscricaoJson).toList());
  }

  Future<void> _inscricaoRoute(HttpRequest request) async {
    final parts =
        request.uri.path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 2 || parts.length > 3) return _finish(request, 404);
    final id = parts[1];
    final mutation = parts.length == 3 &&
        request.method == 'POST' &&
        (parts[2] == 'cancelamento' || parts[2] == 'confirmacao');
    if (mutation) return _inscricaoMutation(request, id);
    if (request.method != 'GET' || parts.length != 2)
      return _finish(request, 405);
    if (!_authorized(request, null)) return;
    final user = _user(request)!;
    final enrollment = _findEnrollment(id);
    if (enrollment == null) return _error(request, 404, 'NAO_ENCONTRADO');
    if (user.role != 'organizacao' && enrollment.participantId != user.id)
      return _error(request, 404, 'NAO_ENCONTRADO');
    _json(request, 200, _inscricaoJson(enrollment));
  }

  Future<void> _inscricaoCreateRoute(
      HttpRequest request, String activityId) async {
    if (request.method != 'POST') return _finish(request, 405);
    if (!_authorized(request, 'participante',
        roleError: 'SOMENTE_PARTICIPANTE')) return;
    final activity = activities[activityId];
    if (activity == null) return _error(request, 404, 'NAO_ENCONTRADO');
    if (await _readMutationBody(request) == _BodyParse.invalid)
      return _error(request, 422, 'DADOS_INVALIDOS');
    await _refreshClockAndReconcile();
    if (activity.cancelled) return _error(request, 422, 'ATIVIDADE_CANCELADA');
    if (!clock.isBefore(activity.meetings.first.start))
      return _error(request, 422, 'INSCRICOES_ENCERRADAS');
    final user = _user(request)!;
    if (_hasActiveEnrollment(user.id, activityId))
      return _error(request, 409, 'JA_INSCRITO');
    if (_hasTimeConflict(user.id, activityId))
      return _error(request, 409, 'CONFLITO_DE_HORARIO');
    if (activity.type == 'minicurso' && _confirmedMinicursos(user.id) >= 2)
      return _error(request, 422, 'LIMITE_DE_MINICURSOS');
    final semVaga = _occupied(activityId) >= activity.slots;
    final enrollment = Enrollment(
        id: _id('ins_'),
        activityId: activityId,
        participantId: user.id,
        status: semVaga ? 'em_espera' : 'confirmada',
        sequenceNumber: ++_enrollmentSequence,
        createdAt: clock);
    enrollments.add(enrollment);
    _dirty = true;
    await _commit();
    _json(request, 201, _inscricaoJson(enrollment));
  }

  Future<void> _inscricaoMutation(HttpRequest request, String id) async {
    if (!_authorized(request, 'participante',
        roleError: 'SOMENTE_PARTICIPANTE')) return;
    final enrollment = _findEnrollment(id);
    if (enrollment == null) return _error(request, 404, 'NAO_ENCONTRADO');
    if (_user(request)!.id != enrollment.participantId)
      return _error(request, 404, 'NAO_ENCONTRADO');
    if (await _readMutationBody(request) == _BodyParse.invalid)
      return _error(request, 422, 'DADOS_INVALIDOS');
    await _refreshClockAndReconcile();
    final parts =
        request.uri.path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts[2] == 'cancelamento') {
      final activity = activities[enrollment.activityId]!;
      if (!clock.isBefore(activity.meetings.first.start))
        return _error(request, 422, 'ATIVIDADE_JA_INICIADA');
      if (enrollment.status == 'cancelada' || enrollment.status == 'expirada')
        return _error(request, 422, 'INSCRICAO_INATIVA');
      enrollment.status = 'cancelada';
      enrollment.convocationDeadline = null;
      _promote(enrollment.activityId);
      _dirty = true;
      await _commit();
      return _json(request, 200, _inscricaoJson(enrollment));
    }
    if (parts[2] != 'confirmacao') return _finish(request, 405);
    if ((enrollment.status == 'convocada' &&
            !clock.isBefore(enrollment.convocationDeadline!)) ||
        (enrollment.status == 'expirada' &&
            enrollment.expiryCause == 'convocacao'))
      return _error(request, 422, 'CONVOCACAO_EXPIRADA');
    if (enrollment.status != 'convocada')
      return _error(request, 422, 'SEM_CONVOCACAO');
    final activity = activities[enrollment.activityId]!;
    if (_hasTimeConflict(enrollment.participantId, enrollment.activityId))
      return _error(request, 409, 'CONFLITO_DE_HORARIO');
    if (activity.type == 'minicurso' &&
        _confirmedMinicursos(enrollment.participantId) >= 2)
      return _error(request, 422, 'LIMITE_DE_MINICURSOS');
    enrollment.status = 'confirmada';
    enrollment.convocationDeadline = null;
    _dirty = true;
    await _commit();
    _json(request, 200, _inscricaoJson(enrollment));
  }

  Enrollment? _findEnrollment(String id) {
    for (final enrollment in enrollments) {
      if (enrollment.id == id) return enrollment;
    }
    return null;
  }

  bool _hasActiveEnrollment(String participantId, String activityId) {
    for (final enrollment in enrollments) {
      if (enrollment.participantId != participantId ||
          enrollment.activityId != activityId) continue;
      if (enrollment.status == 'confirmada' ||
          enrollment.status == 'em_espera' ||
          enrollment.status == 'convocada') return true;
    }
    return false;
  }

  bool _hasTimeConflict(String participantId, String activityId) {
    final candidate = activities[activityId]!;
    for (final enrollment in enrollments) {
      if (enrollment.participantId != participantId ||
          enrollment.status != 'confirmada' ||
          enrollment.activityId == activityId) continue;
      final other = activities[enrollment.activityId]!;
      for (final a in candidate.meetings)
        for (final b in other.meetings)
          if (a.start.isBefore(b.end) && b.start.isBefore(a.end)) return true;
    }
    return false;
  }

  int _confirmedMinicursos(String participantId) {
    var count = 0;
    for (final enrollment in enrollments) {
      if (enrollment.participantId != participantId ||
          enrollment.status != 'confirmada') continue;
      if (activities[enrollment.activityId]!.type == 'minicurso') count++;
    }
    return count;
  }

  void _reconcile() {
    for (final activity in activities.values) {
      _reconcileActivity(activity);
    }
  }

  void _reconcileActivity(Activity activity) {
    final start = activity.meetings.first.start;
    while (true) {
      Enrollment? vencida;
      for (final enrollment in enrollments) {
        if (enrollment.activityId != activity.id ||
            enrollment.status != 'convocada') continue;
        final deadline = enrollment.convocationDeadline!;
        if (vencida == null || deadline.isBefore(vencida.convocationDeadline!))
          vencida = enrollment;
      }
      if (vencida == null) {
        if (clock.isBefore(start)) return;
        break;
      }
      final vencimento = vencida.convocationDeadline!;
      if (vencimento.isAfter(clock)) return;
      if (!vencimento.isBefore(start)) break;
      _expirarPorVencimento(vencida);
      _promote(activity.id, at: vencimento);
    }
    for (final enrollment in enrollments) {
      if (enrollment.activityId != activity.id) continue;
      if (enrollment.status == 'convocada') {
        _expirarPorVencimento(enrollment);
      } else if (enrollment.status == 'em_espera') {
        enrollment.status = 'expirada';
        enrollment.expiryCause = 'fechamento';
        enrollment.convocationDeadline = null;
        _dirty = true;
      }
    }
  }

  void _expirarPorVencimento(Enrollment enrollment) {
    enrollment.status = 'expirada';
    enrollment.expiryCause = 'convocacao';
    enrollment.convocationDeadline = null;
    _dirty = true;
  }

  void _promote(String activityId, {DateTime? at}) {
    final activity = activities[activityId]!;
    final instant = at ?? clock;
    if (!instant.isBefore(activity.meetings.first.start)) return;
    final startLimit = activity.meetings.first.start;
    while (_occupied(activityId) < activity.slots) {
      Enrollment? next;
      for (final enrollment in enrollments) {
        if (enrollment.activityId != activityId ||
            enrollment.status != 'em_espera') continue;
        if (next == null || enrollment.sequenceNumber < next.sequenceNumber)
          next = enrollment;
      }
      if (next == null) return;
      final deadline = instant.add(const Duration(hours: 24));
      next.status = 'convocada';
      next.convocationDeadline =
          deadline.isBefore(startLimit) ? deadline : startLimit;
      next.expiryCause = null;
      _dirty = true;
    }
  }

  int _waitingPosition(Enrollment enrollment) {
    var position = 1;
    for (final other in enrollments) {
      if (other.activityId != enrollment.activityId ||
          other.status != 'em_espera') continue;
      if (other.id != enrollment.id &&
          other.sequenceNumber < enrollment.sequenceNumber) position++;
    }
    return position;
  }

  Map<String, Object?> _inscricaoJson(Enrollment enrollment) => {
        'id': enrollment.id,
        'atividadeId': enrollment.activityId,
        'participanteId': enrollment.participantId,
        'status': enrollment.status,
        'posicaoNaEspera': enrollment.status == 'em_espera'
            ? _waitingPosition(enrollment)
            : null,
        'convocadaAte': enrollment.status == 'convocada'
            ? _formatDate(enrollment.convocationDeadline!)
            : null,
        'criadaEm': _formatDate(enrollment.createdAt),
      };

  Future<Object?> _body(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) return null;
    try {
      final value = jsonDecode(text);
      if (value is! Map && value is! List) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<_BodyParse> _readMutationBody(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) return _BodyParse.valid;
    try {
      return jsonDecode(text) is Map ? _BodyParse.valid : _BodyParse.invalid;
    } catch (_) {
      return _BodyParse.invalid;
    }
  }

  void _error(HttpRequest request, int status, String code) =>
      _json(request, status, ApiError(code).toJson());
  void _json(HttpRequest request, int status, Object body) {
    request.response.headers.contentType = ContentType.json;
    request.response.statusCode = status;
    request.response.write(jsonEncode(body));
    request.response.close();
  }

  void _finish(HttpRequest request, int status) {
    request.response.statusCode = status;
    request.response.close();
  }
}

enum _BodyParse { valid, invalid }
