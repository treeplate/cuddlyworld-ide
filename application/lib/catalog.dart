import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'atom_widget.dart';
import 'data_model.dart';
import 'disposition.dart';

const double kCatalogWidth = 350.0;

class Catalog extends StatefulWidget {
  const Catalog({super.key});
  @override
  _CatalogState createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> with SingleTickerProviderStateMixin {
  List<Atom> _atoms = <Atom>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final Atom element in _atoms) {
      element.removeListener(_handleListUpdate);
    }
    _atoms = AtomsDisposition.of(context).atoms.toList();
    _handleListUpdate();
    for (final Atom element in _atoms) {
      element.addListener(_handleListUpdate);
    }
  }

  void _handleListUpdate() {
    setState(() {
      _atoms.sort();
    });
  }

  @override
  void dispose() {
    for (final Atom element in _atoms) {
      element.removeListener(_handleListUpdate);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 36.0),
        child: FocusTraversalGroup(
          child: ListView(
            children: _atoms
                .map<Widget>((Atom e) => CatalogAtomWidget(atom: e))
                .toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          EditorDisposition.of(context).current =
              AtomsDisposition.of(context).add();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CatalogAtomWidget extends StatefulWidget {
  const CatalogAtomWidget({required this.atom, super.key});

  final Atom atom;

  @override
  _CatalogAtomWidgetState createState() => _CatalogAtomWidgetState();
}

class _CatalogAtomWidgetState extends State<CatalogAtomWidget> {
  Timer? _timer;

  void _trigger() {
    EditorDisposition.of(context).current = widget.atom;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EditorDisposition editor = EditorDisposition.of(context);
    return MouseRegion(
      onEnter: (PointerEnterEvent event) {
        if (event.buttons != 0) {
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 1), _trigger);
        }
      },
      onExit: (PointerExitEvent event) {
        _timer?.cancel();
        _timer = null;
      },
      child: Draggable<Atom>(
        data: widget.atom,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Material(
            type: MaterialType.transparency,
            child: AtomWidget(
              atom: widget.atom,
              startFromCatalog: true,
            ),
          ),
        ),
        child: AtomWidget(
          atom: widget.atom,
          onTap: () {
            setState(() {
              EditorDisposition.of(context).current = widget.atom;
            });
          },
          inCatalog: true,
          icon: Icon(
            editor.cartHolds(widget.atom) ? Icons.shopping_cart : null,
            size: 16.0,
          ),
        ),
      ),
    );
  }
}
