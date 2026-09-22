import 'dart:io';

import 'package:semana_academica_api/server.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3000;
  final modoTeste = Platform.environment['MODO_TESTE'] == '1';
  final arquivoEstado = Platform.environment['ARQUIVO_ESTADO'];
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final api = ApiServer(
    modoTeste: modoTeste,
    stateFile: arquivoEstado != null && arquivoEstado.isNotEmpty
        ? arquivoEstado
        : null,
  );
  stdout
      .writeln('Servidor Dart rodando na porta $port (MODO_TESTE=$modoTeste)');
  await for (final request in server) {
    api.handle(request);
  }
}
