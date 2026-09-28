import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ManualViewerPage extends StatefulWidget {
  const ManualViewerPage({super.key});

  @override
  State<ManualViewerPage> createState() => _ManualViewerPageState();
}

class _ManualViewerPageState extends State<ManualViewerPage> {
  final PdfViewerController _pdfViewerController =
  PdfViewerController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,

      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 24,
      ),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(
          children: [

            // =====================================================
            // ENCABEZADO
            // =====================================================

            Container(
              height: 62,

              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),

              color: const Color(0xFF1E4632),

              child: Row(
                children: [

                  // Icono
                  const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 26,
                  ),

                  const SizedBox(width: 10),

                  // Título
                  const Expanded(
                    child: Text(
                      'Ayuda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // =================================================
                  // BOTÓN CERRAR
                  // =================================================

                  IconButton(
                    tooltip: 'Cerrar manual',

                    onPressed: () {
                      Navigator.of(context).pop();
                    },

                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // VISOR DEL PDF
            // =====================================================

            Expanded(
              child: SfPdfViewer.asset(
                'assets/manual/manual_instalacion_uso.pdf',

                controller: _pdfViewerController,

                pageLayoutMode:
                PdfPageLayoutMode.continuous,

                scrollDirection:
                PdfScrollDirection.vertical,

                pageSpacing: 8,
              ),
            ),

            // =====================================================
            // BARRA INFERIOR
            // =====================================================

            Container(
              height: 48,

              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F5),

                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.20),
                  ),
                ),
              ),

              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.swipe_vertical,
                    size: 18,
                    color: Color(0xFF1E4632),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Desliza para consultar el manual',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}