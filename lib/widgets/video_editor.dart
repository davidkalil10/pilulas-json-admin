import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';

class VideoEditorDialog extends StatefulWidget {
  final TutorialVideo video;
  final Function(TutorialVideo) onSave;
  final bool isNew;

  const VideoEditorDialog({Key? key, required this.video, required this.onSave, this.isNew = false}) : super(key: key);

  @override
  _VideoEditorDialogState createState() => _VideoEditorDialogState();
}

class _VideoEditorDialogState extends State<VideoEditorDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TutorialVideo _editedVideo;

  final _languages = ['pt', 'en', 'es', 'fr'];
  final Map<String, TextEditingController> _tituloControllers = {};
  final Map<String, TextEditingController> _subtituloControllers = {};
  final Map<String, TextEditingController> _tagsControllers = {};
  final Map<String, TextEditingController> _urlControllers = {};
  late TextEditingController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _languages.length, vsync: this);

    // Clona o vídeo para edição local, para não alterar o original até salvar
    _editedVideo = TutorialVideo(
        titulo: Map.from(widget.video.titulo),
        subtitulo: Map.from(widget.video.subtitulo),
        tags: Map.from(widget.video.tags),
        url: Map.from(widget.video.url),
        thumbnail: widget.video.thumbnail,
        dataAtualizacao: widget.video.dataAtualizacao
    );

    _thumbnailController = TextEditingController(text: _editedVideo.thumbnail);

    for (var lang in _languages) {
      _tituloControllers[lang] = TextEditingController(text: _editedVideo.titulo[lang] ?? '');
      _subtituloControllers[lang] = TextEditingController(text: _editedVideo.subtitulo[lang] ?? '');
      _tagsControllers[lang] = TextEditingController(text: (_editedVideo.tags[lang] as List<dynamic>?)?.join(', ') ?? '');
      _urlControllers[lang] = TextEditingController(text: _editedVideo.url[lang] ?? '');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _thumbnailController.dispose();
    _tituloControllers.values.forEach((c) => c.dispose());
    _subtituloControllers.values.forEach((c) => c.dispose());
    _tagsControllers.values.forEach((c) => c.dispose());
    _urlControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _onSave() {
    // Atualiza o objeto _editedVideo com os dados dos controllers
    for (var lang in _languages) {
      _editedVideo.titulo[lang] = _tituloControllers[lang]!.text;
      _editedVideo.subtitulo[lang] = _subtituloControllers[lang]!.text;
      _editedVideo.tags[lang] = _tagsControllers[lang]!.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      _editedVideo.url[lang] = _urlControllers[lang]!.text;
    }
    _editedVideo.thumbnail = _thumbnailController.text;
    // Se for um vídeo novo, atualiza a data
    if (widget.isNew) {
      final now = DateTime.now();
      _editedVideo.dataAtualizacao = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    }

    widget.onSave(_editedVideo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // --- ESTILO AlertDialog ---
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          Icon(widget.isNew ? Icons.add_to_photos_outlined : Icons.edit_note_outlined, color: Colors.blue[700]),
          const SizedBox(width: 10),
          Text(widget.isNew ? 'Adicionar Novo Vídeo' : 'Editar Vídeo'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: DefaultTabController(
          length: _languages.length,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Para não estourar a tela
            children: [
              TextField(
                controller: _thumbnailController,
                decoration: InputDecoration(
                  labelText: 'URL da Thumbnail do Vídeo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                tabs: _languages.map((lang) => Tab(text: lang.toUpperCase())).toList(),
                indicatorColor: Colors.blue[700],
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 16),
              // Conteúdo das abas
              SizedBox(
                height: 350, // Altura fixa para o conteúdo das abas
                child: TabBarView(
                  controller: _tabController,
                  children: _languages.map((lang) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Column(
                        children: [
                          _buildTextField(controller: _tituloControllers[lang]!, label: 'Título'),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _subtituloControllers[lang]!, label: 'Subtítulo', maxLines: 3),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _tagsControllers[lang]!, label: 'Tags (separadas por vírgula)'),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _urlControllers[lang]!, label: 'URL do Vídeo'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Salvar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
  // Helper para criar os TextFields com estilo
  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true, // Melhora alinhamento para multiline
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

}