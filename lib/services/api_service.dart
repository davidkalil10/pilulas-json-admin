// Em um arquivo de serviço, por exemplo
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> saveDataToJsonBin(Map<String, dynamic> updatedData) async {
  // SUAS CHAVES (NÃO COLOQUE EM REPOSITÓRIO PÚBLICO EM PROJETOS REAIS)
  const String binId = '689c0085ae596e708fc8b523';
  const String apiKey = r"$2a$10$z4gvUqvUkckUTJPCEi/Rwe4srIJhwn229aZaDgSiaX/6Fmsb5KAZW";

  final url = Uri.parse('https://api.jsonbin.io/v3/b/$binId');
  print (url);
  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Master-Key': apiKey,
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      print("Dados atualizados com sucesso no JSONBin!");
      return true; // Sucesso
    } else {
      print("Falha ao atualizar: ${response.statusCode} ${response.body}");
      return false; // Falha
    }
  } catch (e) {
    print("Erro na chamada de rede: $e");
    return false; // Falha
  }
}