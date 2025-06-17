import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class EditorScreen extends StatefulWidget {
  final String svgString;
  final Map<String, String> metadata;
  final Function(String) onSave;

  const EditorScreen({
    super.key,
    required this.svgString,
    required this.metadata,
    required this.onSave,
  });

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late XmlDocument svgDocument;
  late String updatedSvgString;
  Map<String, String> editableMetadata = {};
  Map<String, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
    _parseSvg();
    _initializeControllers();
  }

  void _parseSvg() {
    svgDocument = XmlDocument.parse(widget.svgString);
    updatedSvgString = widget.svgString;
    editableMetadata = Map.from(widget.metadata);
  }

  void _initializeControllers() {
    for (var entry in editableMetadata.entries) {
      textControllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  void _updateMetadata(String key, String value) {
    setState(() {
      editableMetadata[key] = value;

      for (var element in svgDocument.findAllElements('path')) {
        if (element.getAttribute(key) != null) {
          element.setAttribute(key, value);
        }
      }

      updatedSvgString = svgDocument.toXmlString(pretty: true);
      print("String$updatedSvgString");
    });
  }
void _showAddMetadataDialog() {
  final keyController = TextEditingController();
  final valueController = TextEditingController();
  String? selectedFieldType;

  final List<String> fieldTypes = [
    'string',
    'number',
    'boolean',
    'color',
    'length',
    'url',
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Metadata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Key (without custom_)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Field Type'),
              value: selectedFieldType,
              items: fieldTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFieldType = value;
                  valueController.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            if (selectedFieldType != null) _buildValueField(selectedFieldType!, valueController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final rawKey = keyController.text.trim();
              final value = valueController.text.trim();

              if (rawKey.isNotEmpty && value.isNotEmpty) {
                final key = "custom_$rawKey";
                final typeKey = "custom_${rawKey}_type";

                textControllers[key] = TextEditingController(text: value);
                textControllers[typeKey] = TextEditingController(text: selectedFieldType);

                setState(() {
                  editableMetadata[key] = value;
                  editableMetadata[typeKey] = selectedFieldType!;

                  for (var element in svgDocument.findAllElements('path')) {
                    element.setAttribute(key, value);
                    element.setAttribute(typeKey, selectedFieldType!);
                  }

                  updatedSvgString = svgDocument.toXmlString(pretty: true);
                  debugPrint(updatedSvgString, wrapWidth: 1024);
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildValueField(String? type, TextEditingController valueController) {
  switch (type) {
    case 'number':
      return TextField(
        controller: valueController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Value (Number)'),
      );
    case 'boolean':
      return DropdownButtonFormField<String>(
        value: valueController.text.isEmpty ? null : valueController.text,
        decoration: const InputDecoration(labelText: 'Value (Boolean)'),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('True')),
          DropdownMenuItem(value: 'false', child: Text('False')),
        ],
        onChanged: (val) {
          valueController.text = val ?? '';
        },
      );
    case 'color':
      return TextField(
        controller: valueController,
        decoration: const InputDecoration(labelText: 'Value (Hex or color name)'),
      );
    case 'url':
      return TextField(
        controller: valueController,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(labelText: 'Value (URL)'),
      );
    case 'length':
      return TextField(
        controller: valueController,
        decoration: const InputDecoration(labelText: 'Value (e.g. 10px, 5%)'),
      );
    default:
      return TextField(
        controller: valueController,
        decoration: const InputDecoration(labelText: 'Value'),
      );
  }
}



  void _saveSvg() async {
    // print("nefore printing");
    //             debugPrint(updatedSvgString, wrapWidth: 1024);
    await Future.delayed(const Duration(milliseconds: 100));
    widget.onSave(updatedSvgString);
    if (mounted) {
      Navigator.pop(context, updatedSvgString);
    }
  }

  @override
  void dispose() {
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit SVG Metadata")),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: SvgPicture.string(updatedSvgString),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              children: editableMetadata.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key, style: const TextStyle(color: Colors.blue)),
                  subtitle: TextField(
                    controller: textControllers[entry.key],
                    style: const TextStyle(color: Colors.green),
                    textDirection: TextDirection.ltr,
                    onChanged: (newValue) {
                      _updateMetadata(entry.key, newValue);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddMetadataDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add Metadata"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveSvg,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Save"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

}
