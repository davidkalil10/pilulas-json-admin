import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/models/categoria.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:pilulasdoconhecimento/services/api_service.dart';
import 'package:pilulasdoconhecimento/widgets/video_editor.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, Categoria>? _data;
  String? _selectedCategory;
  bool _isLoading = true;
  bool _hasChanges = false;
  String _errorMessage = '';

  static const String _binId = '689c0085ae596e708fc8b523';
  static const String _apiKey = r'$2a$10$z4gvUqvUkckUTJPCEi/Rwe4srIJhwn229aZaDgSiaX/6Fmsb5KAZW';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- LÓGICA DE DADOS ---

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      const url = 'https://api.jsonbin.io/v3/b/$_binId/latest';
      final response = await http.get(Uri.parse(url), headers: {'X-Master-Key': _apiKey});

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> record = responseData['record'];

        setState(() {
          _data = record.map((key, value) => MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
          if (_data?.isNotEmpty ?? false) {
            _selectedCategory = _data!.keys.first;
          }
        });

      } else {
        throw Exception('Falha ao carregar dados: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao buscar dados: ${e.toString()}";
      });
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_data == null || !_hasChanges) return;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Salvando...')]))
    );

    final success = await saveDataToJsonBin(_dataAsJsonMap());

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!'), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar os dados. Tente novamente.'), backgroundColor: Colors.red)
      );
    }
  }

  Map<String, dynamic> _dataAsJsonMap() {
    if (_data == null) return {};
    return _data!.map((key, categoria) => MapEntry(key, categoria.toJson()));
  }

  void _editVideo(TutorialVideo video) {
    final videoCopy = TutorialVideo.fromJson(video.toJson());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoEditorDialog(
        video: videoCopy,
        onSave: (updatedVideo) {
          setState(() {
            final index = _data![_selectedCategory]!.videos.indexOf(video);
            if (index != -1) {
              _data![_selectedCategory]!.videos[index] = updatedVideo;
              _hasChanges = true;
            }
          });
        },
      ),
    );
  }

  void _addVideo() {
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final newVideo = TutorialVideo(
      titulo: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      subtitulo: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      tags: {'pt': [], 'en': [], 'es': [], 'fr': []},
      url: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      thumbnail: '',
      dataAtualizacao: formattedDate,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoEditorDialog(
        video: newVideo,
        isNew: true,
        onSave: (savedVideo) {
          setState(() {
            _data![_selectedCategory]!.videos.add(savedVideo);
            _hasChanges = true;
          });
        },
      ),
    );
  }

  void _deleteVideo(TutorialVideo video) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Você tem certeza que deseja excluir o vídeo "${video.titulo['pt'] ?? 'este vídeo'}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                setState(() {
                  _data![_selectedCategory]!.videos.remove(video);
                  _hasChanges = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        )
    );
  }

  // --- BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração | Pílulas do Conhecimento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF37474F), Color(0xFF263238)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: _saveData,
                icon: const Icon(Icons.save_as_outlined, size: 20),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
          : _data == null || _data!.isEmpty
          ? const Center(child: Text('Nenhum dado encontrado ou o "bin" está vazio.'))
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSideMenu(),
          const VerticalDivider(width: 1, thickness: 1),
          _buildMainContent(),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI COM ESTILO PREMIUM ---

  Widget _buildSideMenu() {
    return Container(
      width: 280,
      color: const Color(0xFFECEFF1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Categorias',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _data!.keys.length,
              itemBuilder: (context, index) {
                final key = _data!.keys.elementAt(index);
                final isSelected = _selectedCategory == key;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.directions_car_filled_outlined,
                      color: isSelected ? Colors.blue[800] : Colors.blueGrey[600],
                    ),
                    title: Text(
                      key,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue[900] : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => setState(() => _selectedCategory = key),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedCategory == null) {
      return const Expanded(child: Center(child: Text('Selecione uma categoria para começar')));
    }

    final videos = _data![_selectedCategory]!.videos;

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Editando: $_selectedCategory',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addVideo,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Adicionar Vídeo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: video.thumbnail.isNotEmpty ? NetworkImage(video.thumbnail) : null,
                          child: video.thumbnail.isEmpty ? const Icon(Icons.video_library_outlined, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.titulo['pt'] ?? 'Vídeo sem título',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.subtitulo['pt'] ?? 'Sem subtítulo',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.orangeAccent),
                          tooltip: 'Editar vídeo',
                          onPressed: () => _editVideo(video),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                          tooltip: 'Excluir vídeo',
                          onPressed: () => _deleteVideo(video),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}