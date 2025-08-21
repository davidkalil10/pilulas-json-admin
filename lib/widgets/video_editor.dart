import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:uuid/uuid.dart';
// Importe seu TutorialVideo...

class VideoEditorDialog extends StatefulWidget {
  final TutorialVideo video;
  final Function(TutorialVideo) onSave;
  final bool isNew;
  const VideoEditorDialog({Key? key, required this.video, required this.onSave, this.isNew = false}) : super(key: key);

  @override
  _VideoEditorDialogState createState() => _VideoEditorDialogState();
}

class _VideoEditorDialogState extends State<VideoEditorDialog> with TickerProviderStateMixin {
  final allLanguages = ['pt', 'en', 'es', 'fr'];
  late List<String> activeLanguages;
  late TabController _tabController;
  late TutorialVideo _editedVideo;
  String? _errorMessage;
  final Map<String, bool> _langActive = {};
  final Map<String, TextEditingController> _tituloControllers = {};
  final Map<String, TextEditingController> _subtituloControllers = {};
  final Map<String, TextEditingController> _tagsControllers = {};
  final Map<String, TextEditingController> _urlControllers = {};
  final Map<String, TextEditingController> _categoriaControllers = {};
  late TextEditingController _thumbnailController;

  @override
  void initState() {
    super.initState();
    // Gera UUID se for novo, mantém se for edição
    String videoId = widget.isNew ? const Uuid().v4() : widget.video.id;

    _editedVideo = TutorialVideo.fromJson(widget.video.toJson());
    //_editedVideo.id = videoId; // garantir o id único e imutável

    // Inicializa idiomas ativos
    for (var lang in allLanguages) {
      _langActive[lang] =
      widget.isNew ? lang == 'pt'
          : ((_editedVideo.titulo[lang] ?? '') != '' ||
          (_editedVideo.subtitulo[lang] ?? '') != '' ||
          ((_editedVideo.tags[lang] ?? []) as List).isNotEmpty ||
          (_editedVideo.url[lang] ?? '') != '' ||
          (_editedVideo.categoria[lang] ?? '') != '');
      _tituloControllers[lang] = TextEditingController(text: _editedVideo.titulo[lang] ?? '');
      _subtituloControllers[lang] = TextEditingController(text: _editedVideo.subtitulo[lang] ?? '');
      _tagsControllers[lang] = TextEditingController(text: (_editedVideo.tags[lang] as List<dynamic>?)?.join(', ') ?? '');
      _urlControllers[lang] = TextEditingController(text: _editedVideo.url[lang] ?? '');
      _categoriaControllers[lang] = TextEditingController(text: _editedVideo.categoria[lang] ?? '');
    }
    _thumbnailController = TextEditingController(text: _editedVideo.thumbnail);

    activeLanguages = allLanguages.where((lang) => _langActive[lang]!).toList();
    _tabController = TabController(length: activeLanguages.isEmpty ? 1 : activeLanguages.length, vsync: this);
  }

  void _updateActiveLanguages() {
    activeLanguages = allLanguages.where((lang) => _langActive[lang]!).toList();
    _tabController.dispose();
    _tabController = TabController(length: activeLanguages.isEmpty ? 1 : activeLanguages.length, vsync: this);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _thumbnailController.dispose();
    _tituloControllers.values.forEach((c) => c.dispose());
    _subtituloControllers.values.forEach((c) => c.dispose());
    _tagsControllers.values.forEach((c) => c.dispose());
    _urlControllers.values.forEach((c) => c.dispose());
    _categoriaControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  bool _validateFields() {
    if (_thumbnailController.text.trim().isEmpty) return false;
    for(final lang in activeLanguages) {
      if (_tituloControllers[lang]!.text.trim().isEmpty ||
          _subtituloControllers[lang]!.text.trim().isEmpty ||
          _tagsControllers[lang]!.text.trim().isEmpty ||
          _urlControllers[lang]!.text.trim().isEmpty ||
          _categoriaControllers[lang]!.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _onSave() {
    if (!_validateFields()) {
      setState(() {
        _errorMessage = 'Preencha todos os campos para os idiomas habilitados!';
      });
      return;
    }
    for (var lang in allLanguages) {
      if (_langActive[lang]!) {
        _editedVideo.titulo[lang] = _tituloControllers[lang]!.text;
        _editedVideo.subtitulo[lang] = _subtituloControllers[lang]!.text;
        _editedVideo.tags[lang] = _tagsControllers[lang]!.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        _editedVideo.url[lang] = _urlControllers[lang]!.text;
        _editedVideo.categoria[lang] = _categoriaControllers[lang]!.text;
      } else {
        _editedVideo.titulo[lang] = '';
        _editedVideo.subtitulo[lang] = '';
        _editedVideo.tags[lang] = [];
        _editedVideo.url[lang] = '';
        _editedVideo.categoria[lang] = '';
      }
    }
    _editedVideo.thumbnail = _thumbnailController.text;
    if (widget.isNew) {
      final now = DateTime.now();
      _editedVideo.dataAtualizacao = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    }
    widget.onSave(_editedVideo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;
    final dialogWidth = isMobile ? media.size.width * 0.96 : media.size.width * 0.7;
    final dialogHeight = isMobile ? media.size.height * 0.95 : media.size.height * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(widget.isNew ? 'Adicionar Novo Vídeo' : 'Editar Vídeo', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _thumbnailController,
              decoration: const InputDecoration(labelText: 'URL da Thumbnail do Vídeo', border: OutlineInputBorder()),
            ),
            if (!widget.isNew)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Row(
                  children: [
                    Text("ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Flexible(child: SelectableText(_editedVideo.id, style: TextStyle(color: Colors.blueAccent))),
                  ],
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: allLanguages.map((lang) =>
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _langActive[lang],
                        onChanged: (v) {
                          setState(() {
                            _langActive[lang] = v ?? false;
                            _updateActiveLanguages();
                          });
                        },
                      ),
                      Text(lang.toUpperCase()),
                    ],
                  )
              ).toList(),
            ),
            if (activeLanguages.isNotEmpty)
              TabBar(
                controller: _tabController,
                tabs: activeLanguages.map((lang) => Tab(text: lang.toUpperCase())).toList(),
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                isScrollable: true,
              ),
            if (activeLanguages.isNotEmpty)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: activeLanguages.map((lang) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(controller: _tituloControllers[lang], decoration: const InputDecoration(labelText: 'Título')),
                          SizedBox(height: 8),
                          TextField(controller: _subtituloControllers[lang], decoration: const InputDecoration(labelText: 'Subtítulo'), maxLines: 3),
                          SizedBox(height: 8),
                          TextField(controller: _categoriaControllers[lang], decoration: const InputDecoration(labelText: 'Categoria')),
                          SizedBox(height: 8),
                          TextField(controller: _tagsControllers[lang], decoration: const InputDecoration(labelText: 'Tags (separadas por vírgula)')),
                          SizedBox(height: 8),
                          TextField(controller: _urlControllers[lang], decoration: const InputDecoration(labelText: 'URL do Vídeo')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(onPressed: _onSave, child: const Text('Salvar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}