import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/models/categoria.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:pilulasdoconhecimento/services/api_service.dart';
import 'package:pilulasdoconhecimento/widgets/video_editor.dart';
// ADICIONE ESTE IMPORT (dependência uuid):
import 'package:uuid/uuid.dart';

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
        isNew: false,
        onSave: (updatedVideo) {
          setState(() {
            final index = _data![_selectedCategory]!.videos.indexWhere((v) => v.id == updatedVideo.id);
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
    final uuid = const Uuid().v4(); // Gera UUID v4 automaticamente
    final newVideo = TutorialVideo(
      titulo: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      subtitulo: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      tags: {'pt': [], 'en': [], 'es': [], 'fr': []},
      url: {'pt': '', 'en': '', 'es': '', 'fr': ''},
      categoria: {'pt': '', 'en': '', 'es': '', 'fr': ''}, // Campo novo
      thumbnail: '',
      dataAtualizacao: formattedDate,
      id: uuid, // atributo imutável
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
                  _data![_selectedCategory]!.videos.removeWhere((v) => v.id == video.id);
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

  // ... categoria CRUD igual sua versão ...

  void _addCategory() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController thumbController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da Categoria', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 16),
            TextField(controller: thumbController, decoration: const InputDecoration(labelText: 'URL da Thumbnail da Categoria', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newThumb = thumbController.text.trim();
              if (newName.isEmpty || newThumb.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos os campos são obrigatórios.'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (!_data!.containsKey(newName)) {
                setState(() {
                  _data![newName] = Categoria(thumbnail: newThumb, videos: []);
                  _selectedCategory = newName;
                  _hasChanges = true;
                });
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Este nome de categoria já existe.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _editCategory(String oldName) {
    final TextEditingController nameController = TextEditingController(text: oldName);
    final TextEditingController thumbController = TextEditingController(text: _data![oldName]!.thumbnail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Categoria "$oldName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Novo Nome', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: thumbController, decoration: const InputDecoration(labelText: 'Nova URL da Thumbnail', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newThumb = thumbController.text.trim();
              if (newName.isEmpty || newThumb.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos os campos são obrigatórios.'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (newName == oldName || !_data!.containsKey(newName)) {
                setState(() {
                  final categoryData = _data![oldName]!;
                  categoryData.thumbnail = newThumb;
                  if (newName != oldName) {
                    _data!.remove(oldName);
                    _data![newName] = categoryData;
                    _selectedCategory = newName;
                  }
                  _hasChanges = true;
                });
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Este nome de categoria já existe.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a categoria "$categoryName" e TODOS os seus vídeos?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() {
                _data!.remove(categoryName);
                if (_selectedCategory == categoryName) {
                  _selectedCategory =_data!.keys.isNotEmpty ? _data!.keys.first : null;
                }
                _hasChanges = true;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
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
        drawer: isMobile && _data != null &&_data!.isNotEmpty
    ? Drawer(
    child: SafeArea(child: _buildSideMenu(isMobile: true)),
    )
        : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : (_data == null || _data!.isEmpty)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhuma categoria encontrada.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Criar a Primeira Categoria'),
            ),
          ],
        ),
      )
          : (isMobile
          ? _buildMainContent(isMobile: true)
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSideMenu(),
          const VerticalDivider(width: 1, thickness: 1),
          _buildMainContent(),
        ],
      )
      ),
    );
  }
  Widget _buildSideMenu({bool isMobile = false}) {
    return Container(
      width: isMobile ? null : 280,
      color: const Color(0xFFECEFF1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categorias',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue[700], size: 28),
                  tooltip: 'Adicionar Nova Categoria',
                  onPressed: _addCategory,
                ),
              ],
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                          tooltip: 'Editar Categoria',
                          onPressed: () => _editCategory(key),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: Colors.red[400]),
                          tooltip: 'Excluir Categoria',
                          onPressed: () => _deleteCategory(key),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = key;
                      });
                      if (isMobile) Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMainContent({bool isMobile = false}) {
    if (_selectedCategory == null) {
      return Expanded(
        child: Center(child: Text('Selecione uma categoria para começar')),
      );
    }
    final videos = _data![_selectedCategory]!.videos;
    final content = Column(
      children: [
        Padding(
          padding: isMobile
              ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
              : const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                label: isMobile ? const Text('Novo') : const Text('Adicionar Vídeo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: isMobile ? const Size(80, 40) : const Size(140, 44),
                  textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, indent: isMobile ? 16 : 24, endIndent: isMobile ? 16 : 24),
        Expanded(
          child: videos.isEmpty
              ? const Center(child: Text('Nenhum vídeo nesta categoria. Clique em "Adicionar Vídeo" para começar.'))
              : ListView.builder(
            padding: EdgeInsets.all(isMobile ? 8 : 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: isMobile ? 10 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8.0 : 14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 22 : 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: video.thumbnail.isNotEmpty ? NetworkImage(video.thumbnail) : null,
                        child: video.thumbnail.isEmpty ? const Icon(Icons.video_library_outlined, color: Colors.grey) : null,
                      ),
                      SizedBox(width: isMobile ? 10 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.titulo['pt'] ?? 'Vídeo sem título',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              video.subtitulo['pt'] ?? 'Sem subtítulo',
                              maxLines: isMobile ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Categoria: ${video.categoria['pt'] ?? ''}',
                              style: TextStyle(color: Colors.blueGrey),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ID: ${video.id}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Colors.orangeAccent, size: isMobile ? 22 : 26),
                        tooltip: 'Editar vídeo',
                        onPressed: () => _editVideo(video),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: isMobile ? 22 : 26),
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
    );
    return isMobile ? content : Expanded(child: content);
  }
}