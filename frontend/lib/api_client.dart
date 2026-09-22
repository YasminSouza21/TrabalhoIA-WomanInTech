import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  ApiFailure(this.status, this.code);
  final int status;
  final String code;
  @override
  String toString() => code;
}

class Inscricao {
  Inscricao(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get atividadeId => json['atividadeId'] as String;
  String get participanteId => json['participanteId'] as String;
  String get status => json['status'] as String;
  int? get posicaoNaEspera => json['posicaoNaEspera'] as int?;
  String? get convocadaAte => json['convocadaAte'] as String?;
  String get criadaEm => json['criadaEm'] as String;
}

class Activity {
  Activity(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get title => json['titulo'] as String;
  String get type => json['tipo'] as String;
  String get situation => json['situacao'] as String;
  int get slots => json['vagas'] as int;
  String get roomId => json['salaId'] as String;
  int get duration => json['cargaHorariaMinutos'] as int;
  List<Map<String, dynamic>> get meetings =>
      (json['encontros'] as List? ?? const []).cast<Map<String, dynamic>>();
}

class Room {
  Room(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get name => json['nome'] as String;
  int get capacity => json['capacidade'] as int;
}

class AppUser {
  const AppUser(this.id, this.name, this.role);
  final String id;
  final String name;
  final String role;
}

class ApiClient {
  static const knownUsers = [
    AppUser('org-ana', 'Ana Beatriz Lima', 'organizacao'),
    AppUser('org-bruno', 'Bruno Tavares', 'organizacao'),
    AppUser('p-carla', 'Carla Mendes Souza', 'participante'),
    AppUser('p-diego', 'Diego Alves', 'participante'),
    AppUser('p-elisa', 'Elisa Fernandes da Rocha', 'participante'),
    AppUser('p-fabio', 'Fábio Nogueira', 'participante'),
    AppUser('p-gabriela', 'Gabriela Moura Castro', 'participante'),
    AppUser('p-heitor', 'Heitor Campos', 'participante'),
    AppUser('p-isadora', 'Isadora Ribeiro dos Santos', 'participante'),
    AppUser('p-joao', 'João Pedro Martins', 'participante'),
  ];
  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:3000',
          ),
      client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  String? user;

  Future<dynamic> _request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (user != null) headers['X-Usuario'] = user!;
    final response = switch (method) {
      'GET' => await client.get(uri, headers: headers),
      'POST' => await client.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'PATCH' => await client.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      _ => throw ArgumentError(method),
    };
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw ApiFailure(
        response.statusCode,
        decoded is Map ? decoded['erro'] as String : 'ERRO_HTTP',
      );
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> activities({
    String? type,
    String? day,
  }) async {
    final query = <String, String>{
      if (type != null && type.isNotEmpty) 'tipo': type,
      if (day != null && day.isNotEmpty) 'dia': day,
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final data = await _request('GET', '/atividades$suffix') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> rooms() async =>
      (await _request('GET', '/salas') as List).cast<Map<String, dynamic>>();
  Future<List<Inscricao>> listarInscricoes({String? atividadeId}) async {
    final query = <String, String>{
      if (atividadeId != null && atividadeId.isNotEmpty)
        'atividadeId': atividadeId,
    };
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final data = await _request('GET', '/inscricoes$suffix') as List;
    return data
        .cast<Map<String, dynamic>>()
        .map((json) => Inscricao(json))
        .toList();
  }
  Future<Inscricao> inscricaoDetalhe(String id) async =>
      Inscricao(await _request('GET', '/inscricoes/$id') as Map<String, dynamic>);
  Future<Inscricao> inscrever(String atividadeId) async => Inscricao(
      await _request('POST', '/atividades/$atividadeId/inscricoes')
          as Map<String, dynamic>);
  Future<Inscricao> cancelarInscricao(String id) async => Inscricao(
      await _request('POST', '/inscricoes/$id/cancelamento')
          as Map<String, dynamic>);
  Future<Inscricao> confirmarConvocacao(String id) async => Inscricao(
      await _request('POST', '/inscricoes/$id/confirmacao')
          as Map<String, dynamic>);
  Future<Map<String, dynamic>> activity(String id) async =>
      await _request('GET', '/atividades/$id') as Map<String, dynamic>;
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async =>
      await _request('POST', '/atividades', body: body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      await _request('PATCH', '/atividades/$id', body: body)
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> cancel(String id) async =>
      await _request('POST', '/atividades/$id/cancelamento', body: {})
          as Map<String, dynamic>;
}
