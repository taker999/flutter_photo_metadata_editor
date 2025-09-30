import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../model/custom_attribute.dart';
import '../model/map_part.dart';
import '../utils/mobile_utils.dart';
import 'widgets/svg_path_widget.dart';

class SvgMapScreen extends StatefulWidget {
  const SvgMapScreen({super.key, required this.svgString});

  final String svgString;

  @override
  State<SvgMapScreen> createState() => _SvgMapScreenState();
}

class _SvgMapScreenState extends State<SvgMapScreen> {
  List<MapPart> _mapParts = [];
  MapPart? _selectedPart;

  double _svgWidth = 1.0;
  double _svgHeight = 1.0;

  String? _svgContent;

  final Map<String, TextEditingController> _controllers = {};

  // Single custom attribute
  CustomAttribute _customAttribute = CustomAttribute();

  @override
  void initState() {
    super.initState();
    _parseSvgData(widget.svgString);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _parseSvgData(String svgString) {
    setState(() {
      _svgContent = svgString;
      _mapParts = [];
      _selectedPart = null;
    });

    final document = XmlDocument.parse(svgString);
    final svgElement = document.rootElement;

    final viewBox = svgElement.getAttribute('viewBox');
    if (viewBox != null) {
      final parts = viewBox.split(' ');
      if (parts.length == 4) {
        _svgWidth = double.tryParse(parts[2]) ?? 1.0;
        _svgHeight = double.tryParse(parts[3]) ?? 1.0;
      }
    } else {
      _svgWidth =
          double.tryParse(svgElement.getAttribute('width') ?? '1') ?? 1.0;
      _svgHeight =
          double.tryParse(svgElement.getAttribute('height') ?? '1') ?? 1.0;
    }

    final List<MapPart> loadedParts = [];
    final paths = document.findAllElements('path');

    for (var element in paths) {
      final id = element.getAttribute('id');
      final pathData = element.getAttribute('d');

      if (id != null && pathData != null && pathData.isNotEmpty) {
        final Map<String, String> attributes = {};
        for (var attr in element.attributes) {
          attributes[attr.name.toString()] = attr.value;
        }
        loadedParts.add(MapPart(
          id: id,
          pathData: pathData,
          attributes: attributes,
        ));
      }
    }

    setState(() {
      _mapParts = loadedParts;
    });
  }

  void _onPartSelected(MapPart part) {
    setState(() {
      _selectedPart = part;
    });
  }

  void _saveChanges() {
    if (_selectedPart == null || _svgContent == null) return;

    final document = XmlDocument.parse(_svgContent!);
    final elementToUpdate = document.findAllElements('path').firstWhere(
          (el) => el.getAttribute('id') == _selectedPart!.id,
    );

    // Remove existing custom attributes first
    final attributesToRemove = <String>[];
    for (var attr in elementToUpdate.attributes) {
      if (attr.name.toString().startsWith('custom_')) {
        attributesToRemove.add(attr.name.toString());
      }
    }
    for (var attrName in attributesToRemove) {
      elementToUpdate.removeAttribute(attrName);
    }

    // Update custom attribute (only if both key and value are non-empty)
    if (_customAttribute.key.isNotEmpty && _customAttribute.value.isNotEmpty) {
      final attrName = 'custom_${_customAttribute.key}';
      elementToUpdate.setAttribute(attrName, _customAttribute.value);
    }

    setState(() {
      // Remove old custom attributes from part
      _selectedPart!.attributes
          .removeWhere((key, value) => key.startsWith('custom_'));

      // Update custom attribute in the part (only if both key and value are non-empty)
      if (_customAttribute.key.isNotEmpty &&
          _customAttribute.value.isNotEmpty) {
        final attrName = 'custom_${_customAttribute.key}';
        _selectedPart!.attributes[attrName] = _customAttribute.value;
      }

      _svgContent = document.toXmlString(pretty: true);
    });

    Navigator.of(context).pop(); // Close the dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Changes applied. Ready to download.'),
          duration: Duration(seconds: 2)),
    );
  }

  void _showEditDialog() {
    if (_selectedPart == null) return;

    // Clear old controllers
    _controllers.forEach((_, controller) => controller.dispose());
    _controllers.clear();

    // Setup controllers only for ID
    if (_selectedPart!.attributes.containsKey('id')) {
      _controllers['id'] = TextEditingController(text: _selectedPart!.id);
    }

    // Reset custom attribute and populate with existing one if present
    _customAttribute = CustomAttribute();

    final existingCustomAttr = _selectedPart!.singleCustomAttribute;
    if (existingCustomAttr != null) {
      final cleanKey = existingCustomAttr.key.replaceFirst('custom_', '');
      _customAttribute = CustomAttribute(
        key: cleanKey,
        fieldType: 'string', // Default type
        value: existingCustomAttr.value,
      );
    }

    final bool isEditing = _selectedPart!.hasCustomAttribute;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Editing: ${_selectedPart!.name}"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ID Field (Read-only)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: _controllers['id'],
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'ID',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Custom Attribute Section (Single attribute)
                      Text(isEditing ? "Edit Metadata" : "Add Metadata",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent)),
                      const SizedBox(height: 16),

                      // Single Custom Attribute
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Key field
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Key (without custom_)',
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    _customAttribute.key = value;
                                  });
                                },
                                controller: TextEditingController(
                                    text: _customAttribute.key)
                                  ..selection = TextSelection.collapsed(
                                      offset: _customAttribute.key.length),
                              ),
                              const SizedBox(height: 12),

                              // Field Type dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Field Type',
                                  isDense: true,
                                ),
                                value: _customAttribute.fieldType,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'string', child: Text('String')),
                                  DropdownMenuItem(
                                      value: 'number', child: Text('Number')),
                                  DropdownMenuItem(
                                      value: 'boolean', child: Text('Boolean')),
                                  DropdownMenuItem(
                                      value: 'color', child: Text('Color')),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    _customAttribute.fieldType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // Value field
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    _customAttribute.value = value;
                                  });
                                },
                                controller: TextEditingController(
                                    text: _customAttribute.value)
                                  ..selection = TextSelection.collapsed(
                                      offset: _customAttribute.value.length),
                                keyboardType:
                                _customAttribute.fieldType == 'number'
                                    ? TextInputType.number
                                    : TextInputType.text,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: _saveChanges, child: const Text("Save")),
              ],
            );
          },
        );
      },
    );
  }

  void _downloadSvg() {
    if (_svgContent != null) {
      downloadSvg(_svgContent!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No SVG content loaded to download.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic SVG Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadSvg,
            tooltip: 'Download Updated SVG',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  // --- Layout for desktop with a list panel ---
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildPartsListPanel()),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: _buildMapView()),
      ],
    );
  }

  // --- Layout for mobile with a list panel ---
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(flex: 3, child: _buildMapView()),
        const Divider(height: 1),
        Expanded(flex: 2, child: _buildPartsListPanel()),
      ],
    );
  }

  // --- Widget for displaying the list of SVG parts ---
  Widget _buildPartsListPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("SVG Parts (${_mapParts.length})",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _mapParts.length,
            itemBuilder: (context, index) {
              final part = _mapParts[index];
              final isSelected = _selectedPart?.id == part.id;

              final customAttrsText = part.customAttributes.isNotEmpty
                  ? part.customAttributes.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((e) =>
              "${e.key.replaceFirst('custom_', '')}: ${e.value}")
                  .join(", ")
                  : null;

              return Card(
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isSelected
                    ? Colors.teal.withValues(alpha: 0.2)
                    : Theme.of(context).cardColor,
                child: ListTile(
                  title: Text(part.name),
                  subtitle: customAttrsText != null
                      ? Text(
                    customAttrsText,
                    style:
                    const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                      : null,
                  onTap: () => _onPartSelected(part),
                  selected: isSelected,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // --- Conditional Edit/Add Button ---
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Visibility(
            visible: _selectedPart != null,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: ElevatedButton.icon(
              icon: Icon(_selectedPart?.hasCustomAttribute == true
                  ? Icons.edit
                  : Icons.add),
              label: Text(_selectedPart?.hasCustomAttribute == true
                  ? "Edit Metadata"
                  : "Add Metadata"),
              onPressed: _showEditDialog,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black,
      child: InteractiveViewer(
        maxScale: 20.0,
        child: Center(
          child: AspectRatio(
            aspectRatio: _svgWidth / _svgHeight,
            child: Stack(
              children: _mapParts.map((part) {
                return SvgPathWidget(
                  part: part,
                  isSelected: _selectedPart?.id == part.id,
                  onSelected: _onPartSelected,
                  svgWidth: _svgWidth,
                  svgHeight: _svgHeight,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
