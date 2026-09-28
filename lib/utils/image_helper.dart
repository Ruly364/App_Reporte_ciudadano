import 'dart:io';
import 'package:path_provider/path_provider.dart';


Future<String> guardarImagenLocal(File imagen) async {
    final dir = await getApplicationDocumentsDirectory();

    final nombre = DateTime.now().millisecondsSinceEpoch.toString();
    final nuevaRuta = '${dir.path}/$nombre.jpg';

    final nuevaImagen = await imagen.copy(nuevaRuta);

    return nuevaImagen.path;
  }