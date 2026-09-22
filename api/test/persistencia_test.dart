import 'dart:convert';
import 'dart:io';

import 'package:semana_academica_api/server.dart';
import 'package:test/test.dart';

Future<HttpResponse> request(ApiServer api, String method, String path,
    {String? user, Object? body}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(api.handle);
  final client = HttpClient();
  final request = await client.openUrl(
      method, Uri.parse('http://127.0.0.1:${server.port}$path'));
  if (user != null) request.headers.set('X-Usuario', user);
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(body is String ? body : jsonEncode(body));
  }
  final response = await request.close();
  final text = await utf8.decoder.bind(response).join();
  await server.close(force: true);
  client.close(force: true);
  return HttpResponse(response.statusCode, text);
}

class HttpResponse {
  HttpResponse(this.status, this.text);
  final int status;
  final String text;
  dynamic get json => text.isEmpty ? null : jsonDecode(text);
}

late Directory tempDir;
late String estadoPath;
DateTime agora = DateTime.utc(2026, 10, 13, 12);
DateTime fakeClock() => agora;

ApiServer novaInstancia() => ApiServer(
    modoTeste: false, stateFile: estadoPath, clockProvider: fakeClock);

Future<HttpResponse> criarAtividade(ApiServer api,
    {int vagas = 2, String dia = '2026-10-19'}) async {
  final resposta = await request(api, 'POST', '/atividades', user: 'org-ana',
      body: {
        'titulo': 'Persistida',
        'tipo': 'palestra',
        'salaId': 'sala-101',
        'vagas': vagas,
        'encontros': [
          {
            'inicio': '${dia}T09:00:00-03:00',
            'fim': '${dia}T10:00:00-03:00'
          }
        ]
      });
  expect(resposta.status, 201, reason: 'fixture valida deve criar a atividade');
  return resposta;
}

Future<HttpResponse> inscrever(
    ApiServer api, String atividadeId, String user) async {
  final resposta = await request(api, 'POST',
      '/atividades/$atividadeId/inscricoes',
      user: user);
  expect(resposta.status, 201, reason: 'inscricao de $user deveria ser 201');
  return resposta;
}

void main() {
  setUp(() {
    final base = Directory('.dart_tool');
    if (!base.existsSync()) base.createSync(recursive: true);
    tempDir = base.createTempSync('persistencia_');
    estadoPath =
        '${tempDir.path}${Platform.pathSeparator}estado.json';
    agora = DateTime.utc(2026, 10, 13, 12);
  });

  tearDown(() {
    if (tempDir.existsSync() && tempDir.path.startsWith('.dart_tool')) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('estado M1/M2 sobrevive a reinicio via arquivo JSON local (R40)',
      () async {
    final instancia1 = novaInstancia();
    final criada = await criarAtividade(instancia1, vagas: 2);
    final atvId = criada.json['id'] as String;
    final encontroId =
        (criada.json['encontros'] as List).single['id'] as String;
    await inscrever(instancia1, atvId, 'p-carla');
    await inscrever(instancia1, atvId, 'p-diego');
    await inscrever(instancia1, atvId, 'p-elisa');
    await inscrever(instancia1, atvId, 'p-fabio');

    final instancia2 = novaInstancia();
    final todas = (await request(instancia2, 'GET', '/inscricoes',
            user: 'org-ana'))
        .json as List;
    expect(todas, hasLength(4));
    expect(todas.map((item) => item['participanteId']).toList(),
        ['p-carla', 'p-diego', 'p-elisa', 'p-fabio']);
    expect(todas.map((item) => item['status']).toList(),
        ['confirmada', 'confirmada', 'em_espera', 'em_espera']);
    expect(todas.map((item) => item['posicaoNaEspera']).toList(),
        [isNull, isNull, 1, 2]);

    final detalhe = await request(instancia2, 'GET', '/atividades/$atvId',
        user: 'p-carla');
    expect(detalhe.json['titulo'], 'Persistida');
    expect(detalhe.json['tipo'], 'palestra');
    expect(detalhe.json['salaId'], 'sala-101');
    expect(detalhe.json['vagas'], 2);
    expect(detalhe.json['encontros'].single['id'], encontroId,
        reason: 'IDs dos encontros preservados no reinicio');
    expect(detalhe.json['ocupadas'], 2);
    expect(detalhe.json['vagasRestantes'], 0);
    expect(detalhe.json['emEspera'], 2);
  });

  test(
      'convocacao, canceladas e ordem FIFO sobrevivem; nova reinscricao vai ao fim da fila (R14, R16, R40)',
      () async {
    final instancia1 = novaInstancia();
    final atvId = (await criarAtividade(instancia1, vagas: 1)).json['id'] as String;
    final carla = (await inscrever(instancia1, atvId, 'p-carla')).json['id'] as String;
    final elisa = (await inscrever(instancia1, atvId, 'p-elisa')).json['id'] as String;
    final gabriela =
        (await inscrever(instancia1, atvId, 'p-gabriela')).json['id'] as String;
    await inscrever(instancia1, atvId, 'p-fabio');
    await request(instancia1, 'POST', '/inscricoes/$carla/cancelamento',
        user: 'p-carla');

    final instancia2 = novaInstancia();
    final convocada = await request(instancia2, 'GET', '/inscricoes/$elisa',
        user: 'p-elisa');
    expect(convocada.json['status'], 'convocada',
        reason: 'convocacao sobrevive ao reinicio');
    expect(convocada.json['convocadaAte'], '2026-10-14T12:00:00Z',
        reason: 'prazo original agora+24h preservado');
    final cancelada = await request(instancia2, 'GET', '/inscricoes/$carla',
        user: 'p-carla');
    expect(cancelada.json['status'], 'cancelada',
        reason: 'cancelada sobrevive ao reinicio');

    await request(instancia2, 'POST', '/inscricoes/$elisa/cancelamento',
        user: 'p-elisa');
    final promovido = await request(instancia2, 'GET',
        '/inscricoes/$gabriela', user: 'p-gabriela');
    expect(promovido.json['status'], 'convocada',
        reason: 'apos reinicio o proximo da fila em FIFO e gabriela, nao fabio');
    expect(promovido.json['convocadaAte'], '2026-10-14T12:00:00Z');

    final nova = await inscrever(instancia2, atvId, 'p-elisa');
    expect(nova.json['id'], isNot(elisa),
        reason: 'nova inscricao, nunca reconvoca o antigo registro');
    expect(nova.json['status'], 'em_espera');
    expect(nova.json['posicaoNaEspera'], 2,
        reason: 'fabio ocupa a posicao 1; a nova elisa vai ao fim da fila');

    final registros = (await request(instancia2, 'GET',
            '/inscricoes?atividadeId=$atvId',
            user: 'org-ana'))
        .json as List;
    expect(registros.map((item) => item['participanteId']).toList(),
        ['p-carla', 'p-elisa', 'p-gabriela', 'p-fabio', 'p-elisa']);
    expect(registros.map((item) => item['status']).toList(),
        ['cancelada', 'cancelada', 'convocada', 'em_espera', 'em_espera']);
  });

  test(
      'expiracao durante intervalo desligado usa o vencimento original em cascata (R23, R24, R40)',
      () async {
    final instancia1 = novaInstancia();
    final atvId =
        (await criarAtividade(instancia1, vagas: 1)).json['id'] as String;
    final carla = (await inscrever(instancia1, atvId, 'p-carla')).json['id'] as String;
    final elisa = (await inscrever(instancia1, atvId, 'p-elisa')).json['id'] as String;
    final gabriela =
        (await inscrever(instancia1, atvId, 'p-gabriela')).json['id'] as String;
    await request(instancia1, 'POST', '/inscricoes/$carla/cancelamento',
        user: 'p-carla');
    final convocada = await request(instancia1, 'GET', '/inscricoes/$elisa',
        user: 'p-elisa');
    expect(convocada.json['convocadaAte'], '2026-10-14T12:00:00Z');

    agora = DateTime.utc(2026, 10, 14, 13);
    final instancia2 = novaInstancia();

    final expirada = await request(instancia2, 'GET', '/inscricoes/$elisa',
        user: 'p-elisa');
    expect(expirada.json['status'], 'expirada',
        reason: 'leitura reprocessa a expiracao ocorrida no intervalo');
    expect(expirada.json['convocadaAte'], isNull);
    final confirmar = await request(instancia2, 'POST',
        '/inscricoes/$elisa/confirmacao',
        user: 'p-elisa');
    expect(confirmar.status, 422,
        reason: 'causa expiracao preservada: vencida devolve CONVOCACAO_EXPIRADA');
    expect(confirmar.json['erro'], 'CONVOCACAO_EXPIRADA',
        reason: 'causa da expiracao sobrevive ao reinicio (vencimento, nao fechamento)');

    final promovido = await request(instancia2, 'GET',
        '/inscricoes/$gabriela', user: 'p-gabriela');
    expect(promovido.json['status'], 'convocada');
    expect(promovido.json['convocadaAte'], '2026-10-15T12:00:00Z',
        reason: 'prazo = vencimento original (10-14T12Z)+24h, nunca agora_da_volta+24h');
  });

  test('producao avanca o relogio em cada request com clock fake injetado', () async {
    final instancia = novaInstancia();
    final atvId =
        (await criarAtividade(instancia, vagas: 2)).json['id'] as String;
    agora = DateTime.utc(2026, 10, 13, 13);
    final carla = await inscrever(instancia, atvId, 'p-carla');
    expect(carla.json['criadaEm'], '2026-10-13T13:00:00Z',
        reason: 'producao le a hora da requisicao, nao a do construtor');
    agora = DateTime.utc(2026, 10, 13, 14);
    final diego = await inscrever(instancia, atvId, 'p-diego');
    expect(diego.json['criadaEm'], '2026-10-13T14:00:00Z',
        reason: 'cada request avanca o relogio real');
  });

  test('MODO_TESTE ignora persistencia: nao le nem escreve o arquivo (R41)',
      () async {
    final arquivo = File(estadoPath);
    arquivo.writeAsStringSync('{"sentinel":true}');
    final instancia = ApiServer(
        modoTeste: true,
        stateFile: estadoPath,
        clockProvider: fakeClock);
    expect((await request(instancia, 'POST', '/_teste/reset')).status, 204,
        reason: 'reset em modo teste nao le nem apaga o arquivo existente');
    expect(arquivo.readAsStringSync(), '{"sentinel":true}');
    final atvId =
        (await criarAtividade(instancia)).json['id'] as String;
    await inscrever(instancia, atvId, 'p-carla');
    expect(arquivo.readAsStringSync(), '{"sentinel":true}',
        reason: 'mutacoes em modo teste ficam em memoria isolada');
    expect(File('$estadoPath.tmp').existsSync(), isFalse,
        reason: 'nenhum arquivo temporario e criado em modo teste');
  });

  test(
      'requisicoes simultaneas na mesma instancia: todos 201, 1 confirmada 7 espera, nada se perde ao reiniciar (R40)',
      () async {
    final instancia1 = novaInstancia();
    final atvId =
        (await criarAtividade(instancia1, vagas: 1)).json['id'] as String;
    const participantes = [
      'p-carla',
      'p-diego',
      'p-elisa',
      'p-fabio',
      'p-gabriela',
      'p-heitor',
      'p-isadora',
      'p-joao',
    ];
    final respostas = await Future.wait(participantes
        .map((participante) => request(instancia1, 'POST',
            '/atividades/$atvId/inscricoes',
            user: participante)));
    for (final resposta in respostas) {
      expect(resposta.status, 201,
          reason: 'concorrencia nao pode devolver 500, obtido ${resposta.status} ${resposta.text}');
      expect(resposta.json['status'], isIn(['confirmada', 'em_espera']));
    }
    final ids = respostas.map((resposta) => resposta.json['id'] as String).toSet();
    expect(ids, hasLength(8), reason: '8 inscricoes com ids distintos');

    final instancia2 = novaInstancia();
    final todas =
        (await request(instancia2, 'GET', '/inscricoes', user: 'org-ana'))
            .json as List;
    expect(todas, hasLength(8),
        reason: 'nenhuma inscricao pode se perder no arquivo com requisicoes simultaneas');
    expect(todas.map((item) => item['id']).toSet(), ids,
        reason: 'IDs gravados identicos aos confirmados nas respostas 201');
    expect(todas.map((item) => item['participanteId']).toSet(),
        participantes.toSet(),
        reason: 'nenhum participante duplicado nem omitido');
    expect(
        todas.where((item) => item['status'] == 'confirmada'),
        hasLength(1),
        reason: 'capacidade 1 garante exatamente uma confirmada');
    final espera = todas
        .where((item) => item['status'] == 'em_espera')
        .toList();
    expect(espera, hasLength(7));
    expect(espera.map((item) => item['posicaoNaEspera']).toList(),
        [1, 2, 3, 4, 5, 6, 7],
        reason: 'sequencia gravada decide a ordem FIFO apos reiniciar');
  });

  test(
      'mutacao cujo corpo demora usa o relogio da chegada do corpo, nao o do inicio da requisicao (R08)',
      () async {
    final instancia = novaInstancia();
    final atvId =
        (await criarAtividade(instancia, vagas: 1)).json['id'] as String;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(instancia.handle);
    final client = HttpClient();
    final requisicao = await client.openUrl('POST',
        Uri.parse('http://127.0.0.1:${server.port}/atividades/$atvId/inscricoes'));
    requisicao.headers.set('X-Usuario', 'p-carla');
    requisicao.headers.contentType = ContentType.json;
    requisicao.write('{');
    await requisicao.flush();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    agora = DateTime.parse('2026-10-19T12:00:00Z');
    requisicao.write('}');
    final resposta = await requisicao.close();
    final texto = await utf8.decoder.bind(resposta).join();
    await server.close(force: true);
    client.close(force: true);

    expect(resposta.statusCode, 422,
        reason: 'atividade ja iniciada enquanto o corpo chegava: nao pode aceitar');
    expect((jsonDecode(texto) as Map)['erro'], 'INSCRICOES_ENCERRADAS');
  });

  test(
      'arquivo de estado corrompido falha claramente na carga, sem apagar o arquivo',
      () async {
    final arquivo = File(estadoPath);
    arquivo.writeAsStringSync('nao-e-json');
    expect(() => novaInstancia(), throwsStateError,
        reason: 'carga falha de forma explicita no construtor');
    expect(arquivo.existsSync(), isTrue,
        reason: 'falha de carga nao apaga o arquivo do usuario');
  });
}