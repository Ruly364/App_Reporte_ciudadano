import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class ExcelService {
  /// Genera y comparte un Excel con los reportes.
  /// [reportes]  : lista de mapas tal como llegan del servidor
  /// [nombreArchivo] : p.ej. "reportes_admin" o "reportes_supervisor"
  static Future<void> exportarReportes({
    required BuildContext context,
    required List reportes,
    required String nombreArchivo,
  }) async {
    try {
      final excel = Excel.createExcel();
      final Sheet hoja = excel['Reportes'];

      // ── Encabezados ──────────────────────────────────────
      final encabezados = [
        'Folio',
        'Tipo de Plaga',
        'Descripción',
        'Status',
        'Estado',
        'Municipio',
        'Localidad',
        'Árboles Afectados',
        'Latitud',
        'Longitud',
        'Fecha Registro',
        'Nombre Registrante',
        'Correo Registrante',
        'Teléfono Registrante',
        'Comentarios',
        'Historial de Status',
      ];

      // Estilo encabezado
      final estiloEncabezado = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int i = 0; i < encabezados.length; i++) {
        final celda = hoja.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        celda.value = TextCellValue(encabezados[i]);
        celda.cellStyle = estiloEncabezado;
      }

      // ── Filas de datos ───────────────────────────────────
      for (int i = 0; i < reportes.length; i++) {
        final r = reportes[i];
        final usuario = r['usuario'] ?? {};

        // Comentarios: uno por línea
        final comentarios = (r['comentarios'] as List? ?? [])
            .map((c) =>
        '${_fecha(c['fechaHora'])} | ${c['nombreUsuario']}: ${c['texto']}')
            .join('\n');

        // Historial: uno por línea
        final historial = (r['historialEstatus'] as List? ?? [])
            .map((h) =>
        '${_fecha(h['fechaHora'])} | ${h['nombreUsuario']}: ${h['estadoAnterior'] ?? 'Inicio'} → ${h['estadoNuevo']}')
            .join('\n');

        final fila = [
          r['folio'] ?? '',
          r['tipoPlaga'] ?? '',
          r['descripcion'] ?? '',
          r['estado'] ?? '',
          r['estadoUbicacion'] ?? '',
          r['municipio'] ?? '',
          r['localidad'] ?? '',
          r['cantidadArboles']?.toString() ?? '0',
          r['latitud']?.toString() ?? '',
          r['longitud']?.toString() ?? '',
          _fecha(r['fecha']),
          usuario['nombre'] ?? '',
          usuario['email'] ?? '',
          usuario['telefono'] ?? '',
          comentarios,
          historial,
        ];

        // Estilo alterno por fila
        final colorFila = i.isEven
            ? ExcelColor.fromHexString('#F1F8E9')
            : ExcelColor.fromHexString('#FFFFFF');

        for (int j = 0; j < fila.length; j++) {
          final celda = hoja.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
          );
          celda.value = TextCellValue(fila[j]);
          celda.cellStyle = CellStyle(
            backgroundColorHex: colorFila,
            textWrapping: TextWrapping.WrapText,
          );
        }
      }

      // Ancho de columnas
      final anchos = [18, 20, 30, 14, 20, 18, 18, 10, 12, 12, 18, 22, 28, 16, 40, 40];
      for (int i = 0; i < anchos.length; i++) {
        hoja.setColumnWidth(i, anchos[i].toDouble());
      }

      // ── Guardar y compartir ──────────────────────────────
      final bytes = excel.encode();
      if (bytes == null) throw Exception('No se pudo generar el archivo');

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/${nombreArchivo}_$timestamp.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Reporte de plagas forestales',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _fecha(String? fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}