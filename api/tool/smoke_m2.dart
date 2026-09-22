import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int porta = 3000;
const String base = 'http://127.0.0.1:$porta';
const Duration _readinessTimeout = Duration(seconds: 30);

String get apiDir => File(Platform.script.toFilePath()).parent.parent.path;

final RegExp idAtividade = RegExp(r'^atv_[0-9a-f]{8}$');
final RegExp idInscricao = RegExp(r'^ins_[0-9a-f]{8}$');
final RegExp idEncontro = RegExp(r'^enc_[0-9a-f]{8}$');

HttpClient? client;
Process? servidor;
int? saidaCodigo;
bool pronto = false;
String servidorLog = '';
StreamSubscription<String>? outSub;
StreamSubscription<String>? errSub;

late String atvId;
late String insCarla;
late String insDiego;
late String insElisa;
late String insFabio;
late String insGabriela;
late String insHeitor;

class ErroDePasso implements Exception {
  ErroDePasso(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

class Resultado {
  Resultado(this.status, this.texto);
  final int status;
  final String texto;
  dynamic get json {
    final limpo = texto.trim();
    if (limpo.isEmpty) return null;
    try {
      return jsonDecode(limpo);
    } catch (_) {
      return limpo;
    }
  }
}

Future<Resultado> req(String metodo, String caminho,
    {String? usuario, String? corpo}) async {
  final r = await client!.openUrl(metodo, Uri.parse('$base$caminho'));
  if (usuario != null) r.headers.set('X-Usuario', usuario);
  if (corpo != null) {
    r.headers.contentType = ContentType.json;
    r.write(corpo);
  }
  final resposta = await r.close();
  final texto = await utf8.decoder.bind(resposta).join();
  return Resultado(resposta.statusCode, texto);
}

bool jsonIgual(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final chave in a.keys) {
      if (!b.containsKey(chave) || !jsonIgual(a[chave], b[chave])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonIgual(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

Map<String, dynamic> mapa(Object? valor) => valor as Map<String, dynamic>;

void verifica(bool condicao, String mensagem) {
  if (!condicao) throw ErroDePasso(mensagem);
}

void statusOk(Resultado z, int esperado, String contexto) {
  if (z.status != esperado) {
    throw ErroDePasso(
        '$contexto: status ${z.status} esperado $esperado (${z.texto})');
  }
}

void jsonOk(Resultado z, Object esperado, String contexto) {
  if (!jsonIgual(z.json, esperado)) {
    throw ErroDePasso(
        '$contexto: JSON esperado ${jsonEncode(esperado)} obtido ${z.texto}');
  }
}

Map<String, Object?> modeloInscricao(String id, String participante, String status,
    {int? posicao,
    String? convocadaAte,
    String criadaEm = '2026-10-13T12:00:00Z'}) {
  return {
    'id': id,
    'atividadeId': atvId,
    'participanteId': participante,
    'status': status,
    'posicaoNaEspera': posicao,
    'convocadaAte': convocadaAte,
    'criadaEm': criadaEm,
  };
}

Future<Process> iniciarServidor() async {
  final env = Map<String, String>.from(Platform.environment)
    ..['MODO_TESTE'] = '1'
    ..['PORT'] = '$porta';
  try {
    return await Process.start('dart', ['run', 'bin/server.dart'],
        workingDirectory: apiDir, environment: env);
  } on ProcessException {
    return await Process.start('dart.bat', ['run', 'bin/server.dart'],
        workingDirectory: apiDir, environment: env);
  }
}

Future<void> s1Reset() async {
  final reset = await req('POST', '/_teste/reset');
  statusOk(reset, 204, 'POST /_teste/reset');
  jsonOk(await req('GET', '/_teste/relogio'), {'agora': '2026-10-13T12:00:00Z'},
      'relogio apos reset');
  for (final usuario in ['p-carla', 'org-ana']) {
    jsonOk(await req('GET', '/inscricoes', usuario: usuario), <Object>[],
        'lista vazia ($usuario)');
  }
  jsonOk(
      await req('GET', '/inscricoes?atividadeId=atv_00000000',
          usuario: 'p-carla'),
      <Object>[],
      'filtro sem inscricoes');
}

Future<void> s2Auth401() async {
  final rotas = <(String, String)>[
    ('GET', '/inscricoes'),
    ('GET', '/inscricoes/ins_00000000'),
    ('POST', '/atividades/atv_00000000/inscricoes'),
    ('POST', '/inscricoes/ins_00000000/cancelamento'),
    ('POST', '/inscricoes/ins_00000000/confirmacao'),
  ];
  for (final (metodo, rota) in rotas) {
    final sem = await req(metodo, rota);
    statusOk(sem, 401, '$metodo $rota sem usuario');
    jsonOk(sem,
        {'erro': 'USUARIO_DESCONHECIDO', 'mensagem': 'USUARIO_DESCONHECIDO'},
        '$metodo $rota sem usuario');
    final nulo = await req(metodo, rota, usuario: 'nao-existe');
    statusOk(nulo, 401, '$metodo $rota usuario inexistente');
    jsonOk(nulo,
        {'erro': 'USUARIO_DESCONHECIDO', 'mensagem': 'USUARIO_DESCONHECIDO'},
        '$metodo $rota usuario inexistente');
  }
}

Future<void> s3Org403() async {
  final rotas = <(String, String)>[
    ('POST', '/atividades/atv_00000000/inscricoes'),
    ('POST', '/inscricoes/ins_00000000/cancelamento'),
    ('POST', '/inscricoes/ins_00000000/confirmacao'),
  ];
  for (final (metodo, rota) in rotas) {
    final z = await req(metodo, rota, usuario: 'org-ana');
    statusOk(z, 403, '$metodo $rota org-ana');
    jsonOk(z, {'erro': 'SOMENTE_PARTICIPANTE', 'mensagem': 'SOMENTE_PARTICIPANTE'},
        '$metodo $rota org-ana');
  }
}

Future<void> s4NaoEncontrado() async {
  final criar = await req('POST', '/atividades/atv_00000000/inscricoes',
      usuario: 'p-carla', corpo: 'nao-json');
  statusOk(criar, 404, 'atividade inexistente precede corpo');
  jsonOk(criar, {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'},
      'atividade inexistente 404');
  for (final usuario in ['p-carla', 'org-ana']) {
    final ler = await req('GET', '/inscricoes/ins_00000000', usuario: usuario);
    statusOk(ler, 404, 'GET inscricao inexistente ($usuario)');
    jsonOk(ler, {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'},
        'GET inscricao inexistente ($usuario)');
  }
  for (final op in ['cancelamento', 'confirmacao']) {
    final z = await req('POST', '/inscricoes/ins_00000000/$op',
        usuario: 'p-carla', corpo: 'nao-json');
    statusOk(z, 404, '$op inexistente precede corpo');
    jsonOk(z, {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'},
        '$op inexistente 404');
  }
}

Future<void> s5Clock() async {
  final controla = await req('PUT', '/_teste/relogio',
      corpo: jsonEncode({'agora': '2026-10-13T09:00:00-03:00'}));
  statusOk(controla, 200, 'PUT /_teste/relogio');
  jsonOk(controla, {'agora': '2026-10-13T12:00:00Z'}, 'PUT relogio responde');
  jsonOk(await req('GET', '/_teste/relogio'), {'agora': '2026-10-13T12:00:00Z'},
      'GET relogio');
}

Future<void> s6CriarAtividade() async {
  final corpo = jsonEncode({
    'titulo': 'Smoke M2',
    'tipo': 'palestra',
    'salaId': 'sala-101',
    'vagas': 1,
    'encontros': [
      {
        'inicio': '2026-10-19T09:00:00-03:00',
        'fim': '2026-10-19T10:00:00-03:00'
      }
    ]
  });
  final criada = await req('POST', '/atividades', usuario: 'org-ana', corpo: corpo);
  statusOk(criada, 201, 'criar atividade');
  final d = mapa(criada.json);
  verifica(idAtividade.hasMatch(d['id'] as String), 'formato id atv_ ${d['id']}');
  final primeiro = mapa((d['encontros'] as List).first);
  verifica(idEncontro.hasMatch(primeiro['id'] as String),
      'formato id enc_ ${primeiro['id']}');
  jsonOk(criada, {
    'id': d['id'],
    'titulo': 'Smoke M2',
    'tipo': 'palestra',
    'salaId': 'sala-101',
    'vagas': 1,
    'encontros': [
      {
        'id': primeiro['id'],
        'inicio': '2026-10-19T12:00:00Z',
        'fim': '2026-10-19T13:00:00Z'
      }
    ],
    'cargaHorariaMinutos': 60,
    'situacao': 'prevista',
    'ocupadas': 0,
    'vagasRestantes': 1,
    'emEspera': 0,
  }, 'modelo atividade');
  atvId = d['id'] as String;
}

Future<void> s7Corpo422() async {
  for (final malformado in ['nao-json', '"apenas-texto"', '[1,2]', '42']) {
    final z = await req('POST', '/atividades/$atvId/inscricoes',
        usuario: 'p-carla', corpo: malformado);
    statusOk(z, 422, 'corpo $malformado');
    jsonOk(z, {'erro': 'DADOS_INVALIDOS', 'mensagem': 'DADOS_INVALIDOS'},
        'corpo $malformado 422');
  }
}

Future<void> s8Inscricoes() async {
  final carla = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-carla');
  statusOk(carla, 201, 'inscrever carla');
  final cj = mapa(carla.json);
  verifica(idInscricao.hasMatch(cj['id'] as String),
      'formato id ins_ ${cj['id']}');
  insCarla = cj['id'] as String;
  jsonOk(carla, modeloInscricao(insCarla, 'p-carla', 'confirmada'),
      'carla confirmada');

  for (final op in ['cancelamento', 'confirmacao']) {
    for (final malformado in ['nao-json', '[1,2]']) {
      final z = await req('POST', '/inscricoes/$insCarla/$op',
          usuario: 'p-carla', corpo: malformado);
      statusOk(z, 422, '$op corpo $malformado');
      jsonOk(z, {'erro': 'DADOS_INVALIDOS', 'mensagem': 'DADOS_INVALIDOS'},
          '$op corpo $malformado 422');
    }
  }

  final diego = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-diego');
  statusOk(diego, 201, 'inscrever diego');
  insDiego = mapa(diego.json)['id'] as String;
  jsonOk(diego, modeloInscricao(insDiego, 'p-diego', 'em_espera', posicao: 1),
      'diego espera pos 1');

  final elisa = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-elisa');
  statusOk(elisa, 201, 'inscrever elisa');
  insElisa = mapa(elisa.json)['id'] as String;
  jsonOk(elisa, modeloInscricao(insElisa, 'p-elisa', 'em_espera', posicao: 2),
      'elisa espera pos 2');
}

Future<void> s9JaInscrito() async {
  final carla = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-carla');
  statusOk(carla, 409, 'repetir carla');
  jsonOk(carla, {'erro': 'JA_INSCRITO', 'mensagem': 'JA_INSCRITO'},
      'JA_INSCRITO carla');
  final diego = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-diego');
  statusOk(diego, 409, 'repetir diego');
  jsonOk(diego, {'erro': 'JA_INSCRITO', 'mensagem': 'JA_INSCRITO'},
      'JA_INSCRITO diego');
}

Future<void> s10Listar() async {
  final todas = await req('GET', '/inscricoes', usuario: 'org-ana');
  statusOk(todas, 200, 'listar org');
  jsonOk(todas, <Object>[
    modeloInscricao(insCarla, 'p-carla', 'confirmada'),
    modeloInscricao(insDiego, 'p-diego', 'em_espera', posicao: 1),
    modeloInscricao(insElisa, 'p-elisa', 'em_espera', posicao: 2),
  ], 'ordem e modelo na lista da org');

  final daCarla = await req('GET', '/inscricoes', usuario: 'p-carla');
  jsonOk(daCarla,
      <Object>[modeloInscricao(insCarla, 'p-carla', 'confirmada')],
      'isolamento carla');

  final filtroDiego = await req('GET', '/inscricoes?atividadeId=$atvId',
      usuario: 'p-diego');
  jsonOk(filtroDiego,
      <Object>[modeloInscricao(insDiego, 'p-diego', 'em_espera', posicao: 1)],
      'filtro mantem isolamento');

  final filtroOrg = await req('GET', '/inscricoes?atividadeId=$atvId',
      usuario: 'org-ana');
  jsonOk(filtroOrg, <Object>[
    modeloInscricao(insCarla, 'p-carla', 'confirmada'),
    modeloInscricao(insDiego, 'p-diego', 'em_espera', posicao: 1),
    modeloInscricao(insElisa, 'p-elisa', 'em_espera', posicao: 2),
  ], 'filtro da org');

  final alheia = await req('GET', '/inscricoes/$insElisa', usuario: 'p-carla');
  statusOk(alheia, 404, 'inscricao alheia');
  jsonOk(alheia, {'erro': 'NAO_ENCONTRADO', 'mensagem': 'NAO_ENCONTRADO'},
      'inscricao alheia 404');

  final orgVe = await req('GET', '/inscricoes/$insElisa', usuario: 'org-ana');
  jsonOk(orgVe, modeloInscricao(insElisa, 'p-elisa', 'em_espera', posicao: 2),
      'org consulta alheia');
}

Future<void> s11Detalhe() async {
  final detalhe = await req('GET', '/atividades/$atvId', usuario: 'p-carla');
  statusOk(detalhe, 200, 'detalhe atividade');
  final d = mapa(detalhe.json);
  verifica(d['ocupadas'] == 1 &&
      d['vagasRestantes'] == 0 &&
      d['emEspera'] == 2, 'contadores 1/0/2 obtido '
      '${d['ocupadas']}/${d['vagasRestantes']}/${d['emEspera']}');
}

Future<void> s12CancelarCarla() async {
  final cancelada = await req('POST', '/inscricoes/$insCarla/cancelamento',
      usuario: 'p-carla');
  statusOk(cancelada, 200, 'cancelar carla');
  jsonOk(cancelada, modeloInscricao(insCarla, 'p-carla', 'cancelada'),
      'cancelamento carla');
  final convocado = await req('GET', '/inscricoes/$insDiego', usuario: 'p-diego');
  jsonOk(convocado,
      modeloInscricao(insDiego, 'p-diego', 'convocada',
          convocadaAte: '2026-10-14T12:00:00Z'),
      'diego convocado com prazo agora+24h');
  final naEspera = await req('GET', '/inscricoes/$insElisa', usuario: 'p-elisa');
  jsonOk(naEspera,
      modeloInscricao(insElisa, 'p-elisa', 'em_espera', posicao: 1),
      'elisa recompactada pos 1');
}

Future<void> s13ConfirmarDiego() async {
  final confirmada = await req('POST', '/inscricoes/$insDiego/confirmacao',
      usuario: 'p-diego');
  statusOk(confirmada, 200, 'confirmar diego');
  jsonOk(confirmada, modeloInscricao(insDiego, 'p-diego', 'confirmada'),
      'confirmacao diego');
  final leitura = await req('GET', '/inscricoes/$insDiego', usuario: 'p-diego');
  jsonOk(leitura, modeloInscricao(insDiego, 'p-diego', 'confirmada'),
      'mutacao observavel na leitura');
}

Future<void> s14AumentarVagas() async {
  final patch = await req('PATCH', '/atividades/$atvId', usuario: 'org-ana',
      corpo: jsonEncode({'vagas': 2}));
  statusOk(patch, 200, 'PATCH vagas=2');
  final d = mapa(patch.json);
  verifica(d['vagas'] == 2 &&
      d['ocupadas'] == 2 &&
      d['vagasRestantes'] == 0 &&
      d['emEspera'] == 0, 'contadores pos-aumento ${d['vagas']}/'
      '${d['ocupadas']}/${d['vagasRestantes']}/${d['emEspera']}');
  final elisa = await req('GET', '/inscricoes/$insElisa', usuario: 'p-elisa');
  jsonOk(elisa,
      modeloInscricao(insElisa, 'p-elisa', 'convocada',
          convocadaAte: '2026-10-14T12:00:00Z'),
      'elisa convocada por aumento de vagas');
}

Future<void> s15CancelarDiego() async {
  final cancelada = await req('POST', '/inscricoes/$insDiego/cancelamento',
      usuario: 'p-diego');
  statusOk(cancelada, 200, 'cancelar diego');
  jsonOk(cancelada, modeloInscricao(insDiego, 'p-diego', 'cancelada'),
      'cancelamento diego');
  final detalhe = await req('GET', '/atividades/$atvId', usuario: 'p-carla');
  final d = mapa(detalhe.json);
  verifica(d['ocupadas'] == 1 &&
      d['vagasRestantes'] == 1 &&
      d['emEspera'] == 0, 'contadores pos-cancelamento ${d['ocupadas']}/'
      '${d['vagasRestantes']}/${d['emEspera']}');
  final elisa = await req('GET', '/inscricoes/$insElisa', usuario: 'p-elisa');
  jsonOk(elisa,
      modeloInscricao(insElisa, 'p-elisa', 'convocada',
          convocadaAte: '2026-10-14T12:00:00Z'),
      'elisa permanece convocada');
}

Future<void> s16Encerramento() async {
  final fabio = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-fabio');
  statusOk(fabio, 201, 'inscrever fabio');
  insFabio = mapa(fabio.json)['id'] as String;
  jsonOk(fabio, modeloInscricao(insFabio, 'p-fabio', 'confirmada'),
      'fabio confirmada');

  final gabriela = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-gabriela');
  statusOk(gabriela, 201, 'inscrever gabriela');
  insGabriela = mapa(gabriela.json)['id'] as String;
  jsonOk(gabriela,
      modeloInscricao(insGabriela, 'p-gabriela', 'em_espera', posicao: 1),
      'gabriela espera pos 1');

  final heitor = await req('POST', '/atividades/$atvId/inscricoes',
      usuario: 'p-heitor');
  statusOk(heitor, 201, 'inscrever heitor');
  insHeitor = mapa(heitor.json)['id'] as String;
  jsonOk(heitor,
      modeloInscricao(insHeitor, 'p-heitor', 'em_espera', posicao: 2),
      'heitor espera pos 2');

  await req('PUT', '/_teste/relogio',
      corpo: jsonEncode({'agora': '2026-10-14T12:00:00Z'}));
  final naBorda = await req('POST', '/inscricoes/$insElisa/confirmacao',
      usuario: 'p-elisa');
  statusOk(naBorda, 422, 'confirmar na borda do vencimento');
  jsonOk(naBorda,
      {'erro': 'CONVOCACAO_EXPIRADA', 'mensagem': 'CONVOCACAO_EXPIRADA'},
      'CONVOCACAO_EXPIRADA na borda');

  await req('PUT', '/_teste/relogio',
      corpo: jsonEncode({'agora': '2026-10-14T12:00:01Z'}));
  final expirada = await req('GET', '/inscricoes/$insElisa', usuario: 'p-elisa');
  jsonOk(expirada, modeloInscricao(insElisa, 'p-elisa', 'expirada'),
      'elisa expirada por leitura');
  final promovida =
      await req('GET', '/inscricoes/$insGabriela', usuario: 'p-gabriela');
  jsonOk(promovida,
      modeloInscricao(insGabriela, 'p-gabriela', 'convocada',
          convocadaAte: '2026-10-15T12:00:00Z'),
      'gabriela convocada com vencimento anterior+24h');
  final restante =
      await req('GET', '/inscricoes/$insHeitor', usuario: 'p-heitor');
  jsonOk(restante,
      modeloInscricao(insHeitor, 'p-heitor', 'em_espera', posicao: 1),
      'heitor ainda espera');
  final meio = await req('GET', '/atividades/$atvId', usuario: 'p-carla');
  final dm = mapa(meio.json);
  verifica(dm['ocupadas'] == 2 &&
      dm['vagasRestantes'] == 0 &&
      dm['emEspera'] == 1, 'contadores na cadeia de expiracao '
      '${dm['ocupadas']}/${dm['vagasRestantes']}/${dm['emEspera']}');

  await req('PUT', '/_teste/relogio',
      corpo: jsonEncode({'agora': '2026-10-19T09:00:00-03:00'}));
  final noInicio =
      await req('GET', '/inscricoes/$insGabriela', usuario: 'p-gabriela');
  jsonOk(noInicio, modeloInscricao(insGabriela, 'p-gabriela', 'expirada'),
      'gabriela expirada na cascata');
  final heitorFim =
      await req('GET', '/inscricoes/$insHeitor', usuario: 'p-heitor');
  jsonOk(heitorFim, modeloInscricao(insHeitor, 'p-heitor', 'expirada'),
      'heitor expirada na cascata');
  final fabioSeguro =
      await req('GET', '/inscricoes/$insFabio', usuario: 'p-fabio');
  jsonOk(fabioSeguro, modeloInscricao(insFabio, 'p-fabio', 'confirmada'),
      'fabio confirmada preservada');
  final emAndamento =
      await req('GET', '/atividades/$atvId', usuario: 'p-carla');
  final deo = mapa(emAndamento.json);
  verifica(deo['situacao'] == 'em_andamento', 'situacao em andamento no inicio');
  verifica(deo['ocupadas'] == 1 &&
      deo['vagasRestantes'] == 1 &&
      deo['emEspera'] == 0, 'contadores no inicio ${deo['ocupadas']}/'
      '${deo['vagasRestantes']}/${deo['emEspera']}');

  await req('PUT', '/_teste/relogio',
      corpo: jsonEncode({'agora': '2026-10-19T10:00:00-03:00'}));
  final encerrada = await req('GET', '/atividades/$atvId', usuario: 'p-carla');
  verifica(mapa(encerrada.json)['situacao'] == 'encerrada',
      'atividade encerrada apos o fim');
}

Future<int> _run() async {
  ServerSocket? sonda;
  try {
    sonda = await ServerSocket.bind(InternetAddress.anyIPv4, porta);
  } on SocketException {
    stdout.writeln('porta $porta ja ocupada: abortando sem tocar o servico '
        'existente');
    return 1;
  }
  await sonda.close();

  stdout.writeln('iniciando dart run bin/server.dart MODO_TESTE=1 PORT=$porta');
  servidor = await iniciarServidor();
  client = HttpClient();
  outSub = servidor!.stdout.transform(utf8.decoder).listen((l) => servidorLog += l);
  errSub = servidor!.stderr.transform(utf8.decoder).listen((l) => servidorLog += l);
  unawaited(servidor!.exitCode.then((codigo) => saidaCodigo = codigo));

  final fim = DateTime.now().add(_readinessTimeout);
  while (DateTime.now().isBefore(fim)) {
    if (saidaCodigo != null) {
      stdout.writeln('servidor encerrou antes do readiness (exit $saidaCodigo):'
          '\n$servidorLog');
      return 1;
    }
    try {
      final z = await req('GET', '/_teste/relogio');
      if (z.status == 200) {
        pronto = true;
        break;
      }
    } on SocketException {
    } on HttpException {
    } catch (_) {
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  if (!pronto) {
    stdout
        .writeln('readiness timeout (${_readinessTimeout.inSeconds}s):'
            '\n$servidorLog');
    return 1;
  }

  final cenarios = <(String, Future<void> Function())>[
    ('S01 reset', s1Reset),
    ('S02 auth 401', s2Auth401),
    ('S03 org 403', s3Org403),
    ('S04 inexistente 404', s4NaoEncontrado),
    ('S05 clock', s5Clock),
    ('S06 criar atividade 1 vaga', s6CriarAtividade),
    ('S07 corpo malformado 422', s7Corpo422),
    ('S08 carla/diego/elisa', s8Inscricoes),
    ('S09 ja inscrito 409', s9JaInscrito),
    ('S10 listar/filtrar/isolar', s10Listar),
    ('S11 detalhe contadores', s11Detalhe),
    ('S12 cancelar carla convoca diego', s12CancelarCarla),
    ('S13 confirmar diego', s13ConfirmarDiego),
    ('S14 aumentar vagas convoca elisa', s14AumentarVagas),
    ('S15 cancelar diego', s15CancelarDiego),
    ('S16 encerramento/expiracao', s16Encerramento),
  ];
  var ok = 0;
  for (final (nome, fn) in cenarios) {
    try {
      await fn();
      ok++;
      stdout.writeln('  [ok] $nome');
    } catch (e) {
      stdout.writeln('  [FALHOU] $nome');
      stdout.writeln('    $e');
      return 1;
    }
  }
  stdout.writeln('resumo: $ok cenarios ok - SMOKE M2 OK');
  return 0;
}

Future<void> _encerrar() async {
  await outSub?.cancel();
  await errSub?.cancel();
  client?.close(force: true);
  final p = servidor;
  if (p == null) return;
  try {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/PID', '${p.pid}', '/T', '/F']);
    } else {
      p.kill(ProcessSignal.sigkill);
    }
  } catch (_) {
    try {
      p.kill();
    } catch (_) {}
  }
}

Future<void> main() async {
  var codigo = 0;
  try {
    codigo = await _run();
  } catch (e) {
    stdout.writeln('erro: $e');
    codigo = 1;
  } finally {
    await _encerrar();
  }
  exit(codigo);
}