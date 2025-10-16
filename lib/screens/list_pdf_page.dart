import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ListPdfPage extends StatefulWidget {
  const ListPdfPage({super.key});

  @override
  State<ListPdfPage> createState() => _ListPdfPageState();
}

class _ListPdfPageState extends State<ListPdfPage> {
  List<FileSystemEntity> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path)
        .listSync()
        .where((f) => f.path.endsWith('.pdf'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (!mounted) return;
    setState(() {
      _pdfFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 PDF enregistrés'),
      ),
      body: _pdfFiles.isEmpty
          ? const Center(child: Text('Aucun PDF enregistré pour le moment'))
          : ListView.builder(
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                final file = _pdfFiles[index];
                final fileName = file.path.split('/').last;
                final lastModif = file.statSync().modified.toLocal().toString().split('.')[0];

                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(fileName, style: TextStyle(fontSize: 14),),
                  subtitle: Text('Modifié le : $lastModif', style: TextStyle(fontSize: 12),),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await File(file.path).delete();
                      _loadPdfFiles();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Supprimé : $fileName')),
                      );
                    },
                  ),
                  onTap: () async {
                    await OpenFilex.open(file.path);
                  },
                );
              },
            ),
    );
  }
}
