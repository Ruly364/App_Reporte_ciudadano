import 'package:flutter/material.dart';

class ImagenVisorPage extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;

  const ImagenVisorPage({
    super.key,
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  State<ImagenVisorPage> createState() => _ImagenVisorPageState();
}

class _ImagenVisorPageState extends State<ImagenVisorPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _indiceActual;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TransformationController _transformController =
  TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(
      initialPage: widget.indiceInicial,
      viewportFraction: 0.92,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    final position = _doubleTapDetails!.localPosition;
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _transformController.value = Matrix4.identity();
    } else {
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      _transformController.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [

            // ── Carrusel ──────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imagenes.length,
              onPageChanged: (i) => setState(() {
                _indiceActual = i;
                _transformController.value = Matrix4.identity();
              }),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: GestureDetector(
                    onDoubleTapDown: _onDoubleTapDown,
                    onDoubleTap: _onDoubleTap,
                    child: InteractiveViewer(
                      transformationController:
                      i == _indiceActual ? _transformController : null,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Hero(
                        tag: 'imagen_${widget.imagenes[i]}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.imagenes[i],
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white30, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Barra superior ────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_indiceActual + 1} / ${widget.imagenes.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Puntos indicadores ────────────────────────────
            if (widget.imagenes.length > 1)
              Positioned(
                bottom: 36, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imagenes.length, (i) {
                    final esActivo = i == _indiceActual;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: esActivo ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: esActivo ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

            // ── Hint de gestos ────────────────────────────────
            Positioned(
              bottom: 70, left: 0, right: 0,
              child: Center(child: _HintZoom()),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintZoom extends StatefulWidget {
  @override
  State<_HintZoom> createState() => _HintZoomState();
}

class _HintZoomState extends State<_HintZoom>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined,
                color: Colors.white70, size: 16),
            SizedBox(width: 6),
            Text(
              'Doble toque para zoom • Desliza para navegar',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}