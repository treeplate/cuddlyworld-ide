import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atom_widget.dart';
import 'backend.dart';
import 'data_model.dart';
import 'disposition.dart';
import 'field_updater.dart';
import 'templates.dart';

const Map<String, String> _enumDescriptions = <String, String>{
  'tpPartOfImplicit': "Part of; isn't mentioned when looking at its parent",
  'tpAmbiguousPartOfImplicit':
      "Part of; placement is made explicit in the name; isn't mentioned when looking at its parent",
  'tpAroundImplicit': "Around; isn't mentioned when looking at its parent",
  'tpAtImplicit': "At; isn't mentioned when looking at its parent",
  'tpOnImplicit': "On; isn't mentioned when looking at its parent",
  'tpPlantedInImplicit':
      "Planted in; isn't mentioned when looking at its parent",
  'tpDirectionalOpening': 'Opening; directional',
  'tpDirectionalPath': 'Path; directional',
  'tpSurfaceOpening': 'Opening; on surface',
  'tpAt': 'At',
  'tpOn': 'On',
  'tpPlantedIn': 'Planted in',
  'tpInstalledIn': 'Installed in',
  'tpIn': 'In',
  'tpEmbedded': 'Embedded',
  'tpCarried': 'Carried',
  //Masses
  'tmLight': 'less than 5 kilograms',
  'tmHeavy': 'between 5 and 25 kilograms',
  'tmPonderous': 'between 25 and 125 kilograms',
  'tmLudicrous': 'more than 125 kilograms',
  //Size
  'tsSmall': 'less than 10 centimeters',
  'tsBig': 'between 0.1 and 1 meters',
  'tsMassive': 'between 1 and 10 meters',
  'tsGigantic': 'between 10 and 100 meters',
  'tsLudicrous': 'more than 100 meters',
};

const Map<String, String> _directionOpposites = <String, String>{
  'cdNorth': 'cdSouth',
  'cdSouth': 'cdNorth',
  'cdEast': 'cdWest',
  'cdWest': 'cdEast',
  'cdSouthWest': 'cdNorthEast',
  'cdNorthEast': 'cdSouthWest',
  'cdSouthEast': 'cdNorthWest',
  'cdNorthWest': 'cdSouthEast',
  'cdUp': 'cdDown',
  'cdDown': 'cdUp',
  'cdIn': 'cdOut',
  'cdOut': 'cdIn',
};

const List<String> _bestDefaultClasses = <String>[
  'TDescribedPhysicalThing',
  'TGroundLocation',
];

String _bestDefaultClassOf(Set<String> classes) {
  for (final String value in _bestDefaultClasses) {
    if (classes.contains(value)) {
      return value;
    }
  }
  return (classes.toList()..sort()).first;
}

class Editor extends StatefulWidget {
  const Editor({super.key, required this.game, required this.atom});

  final CuddlyWorld game;

  final Atom atom;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  @override
  void initState() {
    super.initState();
    widget.game.addListener(_updateProperties);
    widget.atom.addListener(_handleAtomUpdate);
    _updateProperties();
  }

  @override
  void didUpdateWidget(Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool dirty = false;
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateProperties);
      widget.game.addListener(_updateProperties);
      dirty = true;
    }
    if (oldWidget.atom != widget.atom) {
      oldWidget.atom.removeListener(_handleAtomUpdate);
      widget.atom.addListener(_handleAtomUpdate);
      dirty = true;
    }
    if (dirty) {
      _updateProperties();
    }
  }

  @override
  void dispose() {
    widget.atom.removeListener(_handleAtomUpdate);
    widget.game.removeListener(_updateProperties);
    super.dispose();
  }

  void _handleAtomUpdate() {
    // TODO(treeplate): check if Atom.deleted
    setState(() {/* atom changed */});
    _updateProperties();
  }

  Map<String, String> _properties = const <String, String>{};

  void _updateProperties() async {
    if (widget.atom.className.isEmpty) {
      _properties = const <String, String>{};
      return;
    }
    try {
      final Map<String, String> properties =
          await widget.game.fetchPropertiesOf(widget.atom.className);
      if (mounted) {
        setState(() {
          _properties = properties;
        });
      }
    } on ConnectionLostException {
      // ignore
    }
  }

  String _prettyName(String property, String type) {
    switch (property) {
      case 'backDescription':
        return 'Description (back)';
      case 'backSide':
        return 'Reverse side';
      case 'cannotMoveExcuse':
        return 'Cannot move excuse';
      case 'cannotPlaceExcuse':
        return 'Cannot place excuse';
      case 'child':
        return type == 'child*' ? 'Children' : 'Child';
      case 'definiteName':
        return 'Name (definite)';
      case 'description':
        return 'Description';
      case 'destination':
        return 'Destination';
      case 'door':
        return 'Door';
      case 'findDescription':
        return 'Description (find)';
      case 'frontDirection':
        return 'Direction of front';
      case 'frontDescription':
        return 'Description (front)';
      case 'frontSide':
        return 'Front side';
      case 'ground':
        return 'Ground';
      case 'hole':
        return 'Hole';
      case 'indefiniteName':
        return 'Name (indefinite)';
      case 'ingredients':
        return 'Ingredients';
      case 'mass':
        return 'Mass';
      case 'source':
        return 'Source';
      case 'maxSize':
        return 'Maximum size';
      case 'name':
        return 'Name';
      case 'landmark':
        return type == 'landmark*' ? 'Landmarks' : 'Landmark';
      case 'opened':
        return 'Opened?';
      case 'openable':
        return 'Openable?';
      case 'pattern':
        return 'Pattern';
      case 'passageWay':
        return 'Passage Way';
      case 'pileClass':
        return 'Pile class';
      case 'position':
        return 'Position';
      case 'size':
        return 'Size';
      case 'surface':
        return 'Surface';
      case 'underDescription':
        return 'Description (under)';
      case 'writing':
        return 'Writing';
      default:
        return property;
    }
  }

  void _updateProperty(String property, PropertyValue? newValue) {
    final PropertyValue? oldValue = widget.atom[property];
    widget.atom[property] = newValue;
    final Map<String, PropertyValue?> updates =
        updateFields(widget.atom, property, oldValue, newValue, _properties);
    assert(!updates.containsKey(property));
    updates.forEach((String property, PropertyValue? value) {
      widget.atom[property] = value;
    });
  }

  Widget _addField(String property, String propertyType) {
    final List<String> parts = propertyType.split(':');
    assert(parts.isNotEmpty);
    assert(parts.length <= 2);
    switch (parts[0]) {
      case 'atom':
        return AtomField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: parts[1],
          value:
              widget.atom.ensurePropertyIs<AtomPropertyValue>(property)?.value,
          parent: widget.atom,
          needsTree: true,
          needsDifferent: true,
          game: widget.game,
          onChanged: (Atom? value) {
            _updateProperty(
                property, value != null ? AtomPropertyValue(value) : null);
          },
        );
      case 'boolean':
        return CheckboxField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          value: widget.atom
              .ensurePropertyIs<BooleanPropertyValue>(property)
              ?.value,
          onChanged: (bool? value) {
            _updateProperty(property, BooleanPropertyValue(value!));
          },
        );
      case 'child*':
        return ChildrenField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: 'TThing',
          values: widget.atom
                  .ensurePropertyIs<ChildrenPropertyValue>(property)
                  ?.value ??
              const <PositionedAtom>[],
          parent: widget.atom,
          game: widget.game,
          onChanged: (List<PositionedAtom> value) {
            _updateProperty(property, ChildrenPropertyValue(value));
          },
        );
      case 'class':
        return ClassesField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: parts[1],
          value: widget.atom
                  .ensurePropertyIs<LiteralPropertyValue>(property)
                  ?.value ??
              '',
          game: widget.game,
          onChanged: (String? value) {
            _updateProperty(property, LiteralPropertyValue(value!));
          },
        );
      case 'enum':
        return EnumField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          enumName: parts[1],
          value: widget.atom
                  .ensurePropertyIs<LiteralPropertyValue>(property)
                  ?.value ??
              '',
          game: widget.game,
          onChanged: (String? value) {
            _updateProperty(property, LiteralPropertyValue(value!));
          },
        );
      case 'landmark*':
        return LandmarksField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: 'TAtom',
          values: widget.atom
                  .ensurePropertyIs<LandmarksPropertyValue>(property)
                  ?.value ??
              const <Landmark>[],
          parent: widget.atom,
          game: widget.game,
          onChanged: (List<Landmark> value) {
            _updateProperty(property, LandmarksPropertyValue(value));
          },
        );
      case 'ingredients':
        return IngredientsField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          values: widget.atom
                  .ensurePropertyIs<IngredientsPropertyValue>(property)
                  ?.value ??
              const <Ingredient>[],
          parent: widget.atom,
          onChanged: (List<Ingredient> value) {
            _updateProperty(property, IngredientsPropertyValue(value));
          },
        );
      case 'string':
        return StringField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          value: widget.atom
                  .ensurePropertyIs<StringPropertyValue>(property)
                  ?.value ??
              '',
          onChanged: (String value) {
            _updateProperty(property, StringPropertyValue(value));
          },
        );
      default:
        return StringField(
          key: ValueKey<String>(property),
          label: '${_prettyName(property, propertyType)} ($propertyType)',
          value: widget.atom
                  .ensurePropertyIs<StringPropertyValue>(property)
                  ?.value ??
              '',
          onChanged: (String value) {
            _updateProperty(property, StringPropertyValue(value));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Atom? parent = widget.atom.parent;
    final EditorDisposition editor = EditorDisposition.of(context);
    return SizedBox.expand(
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicWidth(
                child: ListBody(
                  children: <Widget>[
                    if (parent != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            editor.current = parent;
                          },
                          icon: const Icon(Icons.arrow_upward),
                          label: makeTextForIdentifier(
                              context, parent.identifier!, parent.className),
                        ),
                      ),
                    StringField(
                      label: 'Identifier',
                      value: widget.atom.identifier!.name,
                      suffix: '_${widget.atom.identifier!.disambiguator}',
                      filter: '[0-9A-Za-z_]+',
                      onChanged: (String value) {
                        widget.atom.identifier = RootDisposition.of(context)
                            .getNewIdentifier(name: value, ignore: widget.atom);
                      },
                    ),
                    ClassesField(
                      label: 'Class',
                      rootClass: widget.atom.rootClass,
                      value: widget.atom.className,
                      game: widget.game,
                      onChanged: (String value) {
                        widget.atom.className = value;
                      },
                    ),
                    for (final String property in _properties.keys)
                      _addField(property, _properties[property]!),
                    Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () {
                              if (editor.cartHolds(widget.atom)) {
                                editor.removeFromCart(widget.atom);
                              }
                              editor.current = null;
                              AtomsDisposition.of(context).remove(widget.atom);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                          ),
                          const SizedBox(width: 24.0),
                          if (editor.cartHolds(widget.atom))
                            OutlinedButton.icon(
                              onPressed: () {
                                editor.removeFromCart(widget.atom);
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Remove from cart'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {
                                editor.addToCart(widget.atom);
                              },
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Add to cart'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

Widget _makeField(String label, FocusNode focusNode, Widget field) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: InkWell(
              onTap: () {
                focusNode.requestFocus();
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('$label:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          field,
        ],
      ),
    ),
  );
}

Widget _makeDropdown(List<String> values, String? value, FocusNode? focusNode,
    ValueSetter<String> onChanged) {
  if (values.isEmpty) {
    return const Text('Not connected...',
        style: TextStyle(fontStyle: FontStyle.italic));
  }
  return DropdownButton<String>(
    items: values
        .map<DropdownMenuItem<String>>(
            (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(_enumDescriptions[value] ?? value),
                ))
        .toList(),
    value: values.contains(value) ? value : null,
    focusNode: focusNode,
    onChanged: (String? value) => onChanged(value!),
  );
}

Widget _pad(Widget child) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: child,
    );

Widget _makeAtomSlot(
  Set<String> classes,
  Atom? value,
  Atom parent,
  ValueSetter<Atom?> onChanged, {
  required bool needsTree,
  required bool needsDifferent,
}) {
  bool _ok(Atom atom) =>
      (!needsTree || parent.canAddToTree(atom)) &&
      (!needsDifferent || parent != atom);
  return DragTarget<Atom>(
    onWillAcceptWithDetails: (DragTargetDetails<Atom>? details) =>
        classes.contains(details!.data.className) && _ok(details.data),
    onAcceptWithDetails: (DragTargetDetails<Atom> details) {
      if (_ok(details.data)) {
        onChanged(details.data);
      }
    },
    builder: (BuildContext context, List<Atom?> candidateData,
        List<Object?> rejectedData) {
      return Material(
        color: const Color(0x0A000000),
        child: Wrap(
          children: <Widget>[
            if (value != null && candidateData.isEmpty)
              _pad(AtomWidget(
                atom: value,
                onDelete: () {
                  onChanged(null);
                },
                onTap: () {
                  EditorDisposition.of(context).current = value;
                },
              )),
            ...candidateData
                .map<Widget>((Atom? atom) => _pad(AtomWidget(atom: atom))),
            ...rejectedData.whereType<Atom>().map<Widget>(
                (Atom atom) => _pad(AtomWidget(atom: atom, color: Colors.red))),
            if (value == null && candidateData.isEmpty && rejectedData.isEmpty)
              _pad(AtomWidget(
                elevation: 0.0,
                label: const SizedBox(width: 64.0, child: Text('')),
                color: const Color(0xFFE0E0E0),
                onTap: (classes.isEmpty)
                    ? null
                    : () {
                        final Atom newAtom = AtomsDisposition.of(context).add()
                          ..className = _bestDefaultClassOf(
                              classes.map((String value) => value).toSet());
                        onChanged(newAtom);
                        EditorDisposition.of(context).current = newAtom;
                      },
              )),
          ],
        ),
      );
    },
  );
}

class StringField extends StatefulWidget {
  const StringField({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.filter,
    this.onChanged,
  });

  final String label;
  final String value;
  final String? suffix;
  final String? filter;
  final ValueSetter<String>? onChanged;

  @override
  State<StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<StringField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(StringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(
        widget.label,
        _focusNode,
        Expanded(
          child: TextField(
            focusNode: _focusNode,
            controller: _controller,
            decoration: InputDecoration(
              filled: true,
              border: InputBorder.none,
              suffix: widget.suffix != null ? Text(widget.suffix!) : null,
            ),
            inputFormatters: <TextInputFormatter>[
              if (widget.filter != null)
                FilteringTextInputFormatter.allow(RegExp(widget.filter!))
            ],
            onChanged: widget.onChanged,
          ),
        ));
  }
}

class UnlabeledStringField extends StatefulWidget {
  const UnlabeledStringField({
    super.key,
    required this.value,
    this.onChanged,
  });

  final String value;
  final ValueSetter<String>? onChanged;

  @override
  State<UnlabeledStringField> createState() => _UnlabeledStringFieldState();
}

class _UnlabeledStringFieldState extends State<UnlabeledStringField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(UnlabeledStringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
            focusNode: _focusNode,
            controller: _controller,
            decoration: const InputDecoration(
              filled: true,
              border: InputBorder.none,
            ),
            onChanged: widget.onChanged,
          );
  }
}

class ClassesField extends StatefulWidget {
  const ClassesField({
    super.key,
    required this.game,
    required this.rootClass,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<ClassesField> createState() => _ClassesFieldState();
}

class _ClassesFieldState extends State<ClassesField> {
  final FocusNode _focusNode = FocusNode();

  List<String> _classes = const <String>[];

  @override
  void initState() {
    super.initState();
    _updateClasses();
    widget.game.addListener(_updateClasses);
  }

  void _updateClasses() async {
    try {
      final List<String> result =
          await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = result;
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(ClassesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
      _updateClasses();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_updateClasses);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(widget.label, _focusNode,
        _makeDropdown(_classes, widget.value, _focusNode, widget.onChanged));
  }
}

class EnumField extends StatefulWidget {
  const EnumField({
    super.key,
    required this.game,
    required this.enumName,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final CuddlyWorld game;
  final String enumName;
  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<EnumField> createState() => _EnumFieldState();
}

class _EnumFieldState extends State<EnumField> {
  late final FocusNode _focusNode;

  List<String> _enumValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateEnumValues();
    widget.game.addListener(_updateEnumValues);
  }

  void _updateEnumValues() async {
    try {
      final List<String> result =
          await widget.game.fetchEnumValuesOf(widget.enumName);
      if (!mounted) {
        return;
      }
      setState(() {
        _enumValues = result;
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(EnumField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateEnumValues);
      widget.game.addListener(_updateEnumValues);
      _updateEnumValues();
    } else if (oldWidget.enumName != widget.enumName) {
      _updateEnumValues();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_updateEnumValues);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(widget.label, _focusNode,
        _makeDropdown(_enumValues, widget.value, _focusNode, widget.onChanged));
  }
}

class CheckboxField extends StatefulWidget {
  const CheckboxField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool? value;
  final ValueSetter<bool?>? onChanged;

  @override
  State<CheckboxField> createState() => _CheckboxFieldState();
}

class _CheckboxFieldState extends State<CheckboxField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(
        widget.label,
        _focusNode,
        Checkbox(
          value: widget.value,
          tristate: widget.value == null,
          onChanged: (bool? value) => widget.onChanged!(value),
        ));
  }
}

class AtomField extends StatefulWidget {
  const AtomField({
    super.key,
    required this.game,
    required this.rootClass,
    required this.label,
    required this.value,
    required this.parent,
    this.needsTree = false,
    this.needsDifferent = false,
    required this.onChanged,
  });

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final Atom? value;
  final Atom? parent;
  final bool needsTree;
  final bool needsDifferent;
  final ValueSetter<Atom?> onChanged;

  @override
  State<AtomField> createState() => _AtomFieldState();
}

class _AtomFieldState extends State<AtomField> {
  final FocusNode _focusNode = FocusNode();

  Set<String> _classes = const <String>{};

  @override
  void initState() {
    super.initState();
    _updateClasses();
    widget.game.addListener(_updateClasses);
  }

  void _updateClasses() async {
    try {
      final List<String> result =
          await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = result.toSet();
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(AtomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
      _updateClasses();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_updateClasses);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(
        widget.label,
        _focusNode,
        Expanded(
          child: _makeAtomSlot(
            _classes,
            widget.value,
            widget.parent!,
            widget.onChanged,
            needsTree: widget.needsTree,
            needsDifferent: widget.needsDifferent,
          ),
        ));
  }
}

class ChildrenField extends StatefulWidget {
  const ChildrenField({
    super.key,
    required this.game,
    required this.rootClass,
    required this.label,
    required this.values,
    required this.parent,
    this.onChanged,
  });

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final List<PositionedAtom> values;
  final Atom? parent;
  final ValueSetter<List<PositionedAtom>>? onChanged;

  @override
  State<ChildrenField> createState() => _ChildrenFieldState();
}

class _ChildrenFieldState extends State<ChildrenField> {
  Set<String> _classes = const <String>{};
  List<String> _thingPositionValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _triggerUpdates();
    widget.game.addListener(_triggerUpdates);
  }

  void _triggerUpdates() {
    _updateClasses();
    _updateThingPositionValues();
  }

  void _updateClasses() async {
    try {
      final List<String> result =
          await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = result.toSet();
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateThingPositionValues() async {
    try {
      final List<String> result =
          await widget.game.fetchEnumValuesOf('TThingPosition');
      if (!mounted) {
        return;
      }
      setState(() {
        _thingPositionValues = result;
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(ChildrenField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_triggerUpdates);
      widget.game.addListener(_triggerUpdates);
      _triggerUpdates();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_triggerUpdates);
    super.dispose();
  }

  Widget _row(
      String? position,
      Atom? atom,
      Function(String? position, Atom? atom) onChanged,
      VoidCallback? onDelete) {
    return Row(
      children: <Widget>[
        // TODO(ianh): this takes up a lot of horizontal space (#74)
        _makeDropdown(_thingPositionValues, position, null, (String? position) {
          onChanged(position, atom);
        }),
        const SizedBox(
          width: 8.0,
        ),
        Expanded(
          child: _makeAtomSlot(_classes, atom, widget.parent!, (Atom? atom) {
            onChanged(position, atom);
          }, needsTree: true, needsDifferent: true),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: onDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.values.length; index += 1) {
      final PositionedAtom entry = widget.values[index];
      rows.add(_row(
        entry.position,
        entry.atom,
        (String? position, Atom? atom) {
          final List<PositionedAtom> newValues = widget.values.toList();
          newValues[index] = PositionedAtom(position, atom);
          widget.onChanged!(newValues);
        },
        () {
          final List<PositionedAtom> newValues = widget.values.toList()
            ..removeAt(index);
          widget.onChanged!(newValues);
        },
      ));
    }
    rows.add(_row(
      '',
      null,
      (String? position, Atom? atom) {
        final List<PositionedAtom> newValues = widget.values.toList()
          ..add(PositionedAtom(position, atom));
        widget.onChanged!(newValues);
      },
      null,
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('${widget.label}:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: ListBody(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

// returns true if [source] has a landmark in [direction] going to [destination]
bool hasSymmetricLandmark(Atom source, String direction, Atom destination) {
  if (source['landmark'] == null) {
    return false;
  }
  return (source['landmark'] as LandmarksPropertyValue).value.any(
        (Landmark landmark) =>
            landmark.direction == _directionOpposites[direction] &&
            landmark.atom == destination,
      );
}

class LandmarksField extends StatefulWidget {
  const LandmarksField({
    super.key,
    required this.game,
    required this.rootClass,
    required this.label,
    required this.values,
    required this.parent,
    this.onChanged,
  });

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final List<Landmark> values;
  final Atom parent;
  final ValueSetter<List<Landmark>>? onChanged;

  @override
  State<LandmarksField> createState() => _LandmarksFieldState();
}

class _LandmarksFieldState extends State<LandmarksField> {
  Set<String> _classes = const <String>{};
  Set<String> _locationTypes = const <String>{};
  List<String> _cardinalDirectionValues = const <String>[];
  List<String> _landmarkOptionValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _triggerUpdates();
    widget.game.addListener(_triggerUpdates);
  }

  void _triggerUpdates() {
    _updateClasses();
    _updateLocationTypes();
    _updateThingPositionValues();
    _updateLandmarkOptionValues();
  }

  void _updateClasses() async {
    try {
      final List<String> result =
          await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted) {
        return;
      }
      setState(() {
        _classes = result.toSet();
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateLocationTypes() async {
    try {
      final List<String> result = await widget.game.fetchClassesOf('TLocation');
      if (!mounted) {
        return;
      }
      setState(() {
        _locationTypes = result.toSet();
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateThingPositionValues() async {
    try {
      final List<String> result =
          await widget.game.fetchEnumValuesOf('TCardinalDirection');
      if (!mounted) {
        return;
      }
      setState(() {
        _cardinalDirectionValues = result;
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateLandmarkOptionValues() async {
    try {
      final List<String> result =
          await widget.game.fetchEnumValuesOf('TLandmarkOption');
      if (!mounted) {
        return;
      }
      setState(() {
        _landmarkOptionValues = result;
      });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(LandmarksField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_triggerUpdates);
      widget.game.addListener(_triggerUpdates);
      _triggerUpdates();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_triggerUpdates);
    super.dispose();
  }

  void putBetweenRooms(Atom start, Landmark landmark, Atom middle) {
    assert(landmark.atom != null,
        'contract violation for putBetweenRooms: landmark has no atom');
    assert(start['landmark'] is LandmarksPropertyValue,
        'contract violation for putBetweenRooms: start has no landmarks');
    assert(_locationTypes.contains(start.className),
        'contract violation for putBetweenRooms: start is not a location');
    assert(_locationTypes.contains(middle.className),
        'contract violation for putBetweenRooms: middle is not a location');
    final Atom end = landmark.atom!;
    assert(end['landmark'] is LandmarksPropertyValue,
        'contract violation for putBetweenRooms: end has no landmarks');
    assert(_locationTypes.contains(end.className),
        'contract violation for putBetweenRooms: end is not a location');
    final String reverseDirection = _directionOpposites[landmark.direction!]!;
    final List<Landmark> startLandmarks =
        (start['landmark'] as LandmarksPropertyValue).value;
    assert(startLandmarks.contains(landmark),
        'contract violation for putBetweenRooms: landmark not in start\'s landmarks');
    final List<Landmark> middleLandmarks =
        (middle['landmark'] as LandmarksPropertyValue?)?.value ?? <Landmark>[];
    final List<Landmark> endLandmarks =
        (end['landmark'] as LandmarksPropertyValue).value;
    assert(endLandmarks.any(
      (Landmark landmark) =>
          landmark.direction == reverseDirection && landmark.atom == start,
    ));
    final Landmark reverseLandmark = endLandmarks.firstWhere(
      (Landmark landmark) =>
          landmark.direction == reverseDirection && landmark.atom == start,
    );
    start['landmark'] = LandmarksPropertyValue(
      startLandmarks
          .map(
            (Landmark landmark2) => landmark2 == landmark
                ? Landmark(landmark.direction, middle, landmark.options)
                : landmark2,
          )
          .toList(),
    );
    middle['landmark'] = LandmarksPropertyValue(
      middleLandmarks +
          <Landmark>[
            Landmark(landmark.direction, end, landmark.options),
            Landmark(reverseDirection, start, reverseLandmark.options),
          ],
    );
    end['landmark'] = LandmarksPropertyValue(
      startLandmarks
          .map(
            (Landmark landmark2) => landmark2 == reverseLandmark
                ? Landmark(
                    reverseLandmark.direction, middle, reverseLandmark.options)
                : landmark2,
          )
          .toList(),
    );
  }

  void generateConnectionAugmentationDialog(Atom start, Landmark landmark) {
    final Iterable<Atom> locations = AtomsDisposition.of(context)
        .atoms
        .where((Atom atom) => _locationTypes.contains(atom.className));
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400.0,
                maxHeight: 400.0,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Augment room with:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ActionChip(
                        label: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        ...templates
                            .where((Blueprint template) => _locationTypes
                                .contains(template.atoms.first.className))
                            .map(
                              (Blueprint blueprint) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: ActionChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      blueprint.icon,
                                      const SizedBox(width: 4),
                                      Text(blueprint.header),
                                    ],
                                  ),
                                  onPressed: () {
                                    putBetweenRooms(
                                      start,
                                      landmark,
                                      createFromTemplate(
                                          AtomsDisposition.of(context),
                                          blueprint.atoms),
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                        ...locations.map(
                          (Atom atom) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ActionChip(
                              label: Text('${atom.identifier}'),
                              onPressed: () {
                                putBetweenRooms(start, landmark, atom);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(
      Landmark? landmark,
      Function(String? direction, Atom? atom, Set<String> options) onChanged,
      VoidCallback? onDelete) {
    final Atom? atom = landmark?.atom;
    final String? direction = landmark?.direction;
    final Set<String> options = landmark?.options ?? <String>{};
    return ListBody(
      children: <Widget>[
        Row(
          children: <Widget>[
            _makeDropdown(_cardinalDirectionValues, direction, null,
                (String? direction) {
              onChanged(direction, atom, options);
            }),
            const SizedBox(
              width: 8.0,
            ),
            Expanded(
              child: _makeAtomSlot(_classes, atom, widget.parent, (Atom? atom) {
                onChanged(direction, atom, options);
              }, needsTree: false, needsDifferent: true),
            ),
            if (direction != null &&
                atom != null &&
                _locationTypes.contains(atom.className))
              if (hasSymmetricLandmark(atom, direction, widget.parent))
                ActionChip(
                  label: const Text('Augment connection'),
                  onPressed: () {
                    generateConnectionAugmentationDialog(
                        widget.parent, landmark!);
                  },
                )
              else
                ActionChip(
                  label: const Text('Add reverse connection'),
                  onPressed: () {
                    final Landmark landmark = Landmark(
                        _directionOpposites[direction], widget.parent, options);
                    if (atom['landmark'] == null) {
                      atom['landmark'] =
                          LandmarksPropertyValue(<Landmark>[landmark]);
                    } else {
                      atom['landmark'] = LandmarksPropertyValue(
                          (atom['landmark'] as LandmarksPropertyValue).value +
                              <Landmark>[landmark]);
                    }
                  },
                ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: onDelete,
              ),
          ],
        ),
        Wrap(
          children: <Widget>[
            for (final String option in _landmarkOptionValues)
              _pad(
                FilterChip(
                  label: Text(option),
                  selected: options.contains(option),
                  onSelected: (bool selected) {
                    if (selected)
                      onChanged(direction, atom, options.toSet()..add(option));
                    else
                      onChanged(
                          direction, atom, options.toSet()..remove(option));
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.values.length; index += 1) {
      final Landmark entry = widget.values[index];
      rows.add(_row(
        entry,
        (String? direction, Atom? atom, Set<String> options) {
          final List<Landmark> newValues = widget.values.toList();
          newValues[index] = Landmark(direction, atom, options);
          widget.onChanged!(newValues);
        },
        () {
          final List<Landmark> newValues = widget.values.toList()
            ..removeAt(index);
          widget.onChanged!(newValues);
        },
      ));
    }
    rows.add(_row(
      null,
      (String? direction, Atom? atom, Set<String> options) {
        final List<Landmark> newValues = widget.values.toList()
          ..add(Landmark(direction, atom, options));
        widget.onChanged!(newValues);
      },
      null,
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('${widget.label}:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: ListBody(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class IngredientsField extends StatefulWidget {
  const IngredientsField({
    super.key,
    required this.label,
    required this.values,
    required this.parent,
    this.onChanged,
  });

  final String label;
  final List<Ingredient> values;
  final Atom parent;
  final ValueSetter<List<Ingredient>>? onChanged;

  @override
  State<IngredientsField> createState() => _IngredientsFieldState();
}

class _IngredientsFieldState extends State<IngredientsField> {
  Widget _row(
      Ingredient ingredient,
      void Function(String? singular, String? plural) onChanged,
      VoidCallback? onDelete) {
    final String singular = ingredient.singular;
    final String plural = ingredient.plural;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: UnlabeledStringField(
              value: singular,
              onChanged: (String newSingular) {
                onChanged(newSingular, null);
              },
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          const Text('/'),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: UnlabeledStringField(
              value: plural,
              onChanged: (String newPlural) {
                onChanged(null, newPlural);
              },
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  // TODO(treeplate): if both singular and plural are changed on the same frame, only one will actually be changed
  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.values.length; index += 1) {
      final Ingredient entry = widget.values[index];
      rows.add(_row(
        entry,
        (String? singular, String? plural) {
          final List<Ingredient> newValues = widget.values.toList();
          newValues[index] = Ingredient(singular ?? entry.singular, plural ?? entry.plural);
          widget.onChanged!(newValues);
        },
        () {
          final List<Ingredient> newValues = widget.values.toList()
            ..removeAt(index);
          widget.onChanged!(newValues);
        },
      ));
    }
    rows.add(_row(
      Ingredient('', ''),
      (String? singular, String? plural) {
        final List<Ingredient> newValues = widget.values.toList()
          ..add(Ingredient(singular ?? '', plural ?? ''));
        widget.onChanged!(newValues);
      },
      null,
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('${widget.label}:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: ListBody(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}
