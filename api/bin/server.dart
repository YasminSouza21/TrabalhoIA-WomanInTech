import 'dart:io';

import 'package:semana_academica_api/server.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3000;
  final modoTeste = Platform.environment['MODO_TESTE'] == '1';
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final api = ApiServer(modoTeste: modoTeste);
  stdout
      .writeln('Servidor Dart rodando na porta $port (MODO_TESTE=$modoTeste)');
  await for (final request in server) {
    api.handle(request);
  }
}
