import 'dart:convert';
import 'dart:io';

const port = 3001;
const base = 'http://127.0.0.1:$port';

class Result {
  Result(this.status, this.body);
  final int status;
  final String body;
  dynamic get json => body.isEmpty ? null : jsonDecode(body);
}

HttpClient? client;
Process? server;

Future<Result> request(String method, String path,
    {String? user, Object? body}) async {
  final request = await client!.openUrl(method, Uri.parse('$base$path'));
  if (user != null) request.headers.set('X-Usuario', user);
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(body is String ? body : jsonEncode(body));
  }
  final response = await request.close();
  return Result(response.statusCode, await utf8.decoder.bind(response).join());
}

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<String> createActivity(String title, String day) async {
  final response = await request('POST', '/atividades', user: 'org-ana', body: {
    'titulo': title,
    'tipo': 'palestra',
    'salaId': title == 'Primeira' ? 'sala-101' : 'sala-102',
    'vagas': 2,
    'encontros': [
      {
        'inicio': '${day}T09:00:00-03:00',
        'fim': '${day}T10:00:00-03:00',
      }
    ],
  });
  check(response.status == 201, 'criar atividade: ${response.body}');
  return response.json['id'] as String;
}

Future<void> setClock(String value) async {
  final response =
      await request('PUT', '/_teste/relogio', body: {'agora': value});
  check(response.status == 200, 'relogio: ${response.body}');
}

Future<void> main() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
  await probe.close();
  final environment = Map<String, String>.from(Platform.environment)
    ..['MODO_TESTE'] = '1'
    ..['PORT'] = '$port';
  try {
    server = await Process.start('dart', ['run', 'bin/server.dart'],
        workingDirectory: Directory.current.path, environment: environment);
    client = HttpClient();
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      try {
        if ((await request('GET', '/_teste/relogio')).status == 200) break;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    check((await request('POST', '/_teste/reset')).status == 204,
        'reset inicial');

    final atividade = await createActivity('Primeira', '2026-10-19');
    final detalhe =
        await request('GET', '/atividades/$atividade', user: 'p-carla');
    final encontro = (detalhe.json['encontros'] as List).single['id'] as String;
    await setClock('2026-10-19T08:45:00-03:00');
    final codigo =
        await request('GET', '/encontros/$encontro/codigo', user: 'org-ana');
    check(codigo.status == 200 && (codigo.json['codigo'] as String).length == 6,
        'obter codigo');
    final inscricao = await request('POST', '/atividades/$atividade/inscricoes',
        user: 'p-carla');
    check(inscricao.status == 201 && inscricao.json['status'] == 'confirmada',
        'inscricao confirmada');
    await request('POST', '/atividades/$atividade/inscricoes', user: 'p-elisa');
    final qr = await request('POST', '/encontros/$encontro/presencas',
        user: 'p-carla', body: {'codigo': codigo.json['codigo']});
    check(qr.status == 201 && qr.json['origem'] == 'qr', 'presenca QR');
    await setClock('2026-10-19T08:55:00-03:00');
    final offline = await request('POST', '/encontros/$encontro/presencas',
        user: 'p-elisa',
        body: {
          'codigo': codigo.json['codigo'],
          'lidoEm': '2026-10-19T08:45:00-03:00',
        });
    check(offline.status == 201 && offline.json['origem'] == 'qr_offline',
        'presenca offline');
    final duplicate = await request('POST', '/encontros/$encontro/presencas',
        user: 'p-carla', body: {'codigo': 'ANTIGO'});
    check(duplicate.status == 200 && duplicate.json['id'] == qr.json['id'],
        'idempotencia QR');
    final malformed = await request('POST', '/encontros/$encontro/presencas',
        user: 'p-elisa', body: '[');
    check(
        malformed.status == 422 && malformed.json['erro'] == 'DADOS_INVALIDOS',
        'corpo QR malformado');
    await request('POST', '/atividades/$atividade/cancelamento',
        user: 'org-ana', body: {});
    final cancelledDuplicate = await request(
        'POST', '/encontros/$encontro/presencas',
        user: 'p-carla', body: {'codigo': 'INVALIDO'});
    check(
        cancelledDuplicate.status == 422 &&
            cancelledDuplicate.json['erro'] == 'ATIVIDADE_CANCELADA',
        'cancelamento antes da idempotencia');
    final listed =
        await request('GET', '/encontros/$encontro/presencas', user: 'org-ana');
    check(
        listed.status == 200 && (listed.json as List).length == 2, 'listagem');

    final segunda = await createActivity('Segunda', '2026-10-20');
    final segundaDetalhe =
        await request('GET', '/atividades/$segunda', user: 'p-diego');
    final segundoEncontro =
        (segundaDetalhe.json['encontros'] as List).single['id'] as String;
    await setClock('2026-10-20T08:45:00-03:00');
    await request('POST', '/atividades/$segunda/inscricoes', user: 'p-diego');
    final missingJustification = await request(
        'POST', '/encontros/$segundoEncontro/presencas/manual',
        user: 'org-ana', body: {'participanteId': 'p-diego'});
    check(
        missingJustification.status == 422 &&
            missingJustification.json['erro'] == 'JUSTIFICATIVA_OBRIGATORIA',
        'justificativa manual ausente');
    final manual = await request(
        'POST', '/encontros/$segundoEncontro/presencas/manual',
        user: 'org-ana',
        body: {
          'participanteId': 'p-diego',
          'justificativa': 'Participacao autorizada',
        });
    check(manual.status == 201 && manual.json['origem'] == 'manual',
        'presenca manual');
    final manualDuplicate = await request(
        'POST', '/encontros/$segundoEncontro/presencas/manual',
        user: 'org-bruno',
        body: {
          'participanteId': 'p-diego',
          'justificativa': 'Outra justificativa',
        });
    check(
        manualDuplicate.status == 200 &&
            manualDuplicate.json['id'] == manual.json['id'],
        'limite manual compartilhado e idempotencia');

    await request('POST', '/atividades/$segunda/cancelamento',
        user: 'org-ana', body: {});
    final cancelledCode = await request(
        'GET', '/encontros/$segundoEncontro/codigo',
        user: 'org-ana');
    check(
        cancelledCode.status == 422 &&
            cancelledCode.json['erro'] == 'ATIVIDADE_CANCELADA',
        'atividade cancelada');
    check(
        (await request('POST', '/_teste/reset')).status == 204, 'reset final');
    check(
        (await request('GET', '/_teste/relogio')).json['agora'] ==
            '2026-10-13T12:00:00Z',
        'relogio apos reset');
    stdout.writeln(
        'SMOKE M3 OK: QR, offline/idempotencia, corpos invalidos, precedencia de cancelamento, manual/justificativa, listagem e reset');
  } finally {
    client?.close(force: true);
    server?.kill(ProcessSignal.sigkill);
  }
}
