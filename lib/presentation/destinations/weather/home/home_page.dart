import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/presentation/base/page/base_page.dart';
import 'package:flutter_template/presentation/base/widgets/theme/theme_picker/theme_picker.dart';
import 'package:flutter_template/presentation/destinations/svg_map/view/svg_map_screen.dart';
import 'package:flutter_template/presentation/destinations/weather/home/home_screen.dart';
import 'package:flutter_template/presentation/destinations/weather/home/home_screen_intent.dart';
import 'package:flutter_template/presentation/destinations/weather/home/home_screen_state.dart';
import 'package:flutter_template/presentation/destinations/weather/home/home_view_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../base/svg_provider/svg_provider.dart';
import 'widgets/home_page_body/home_page_body.dart';

@RoutePage()
class HomePage extends ConsumerWidget {
  final HomeScreen homeScreen;

  const HomePage({
    super.key,
    this.homeScreen = const HomeScreen(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage<HomeScreen, HomeScreenState, HomeViewModel>(
      viewModelProvider: homeViewModelProvider,
      screen: homeScreen,
      appBarActions: () => [
        IconButton(
          onPressed: () {
            String locale = context.locale.toString();
            if (locale == "hi_IN") {
              context.setLocale(const Locale("en", "US"));
            } else {
              context.setLocale(const Locale("hi", "IN"));
            }
          },
          icon: const Icon(Icons.language),
        ),
        IconButton(
          onPressed: () {
            final viewModel = ref.watch(homeViewModelProvider.notifier);
            viewModel.onIntent(const SearchHomeScreenIntent());
          },
          icon: const Icon(Icons.search),
        ),
        const ThemePicker(),
      ],
      body: const HomePageBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndLoadSvg(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _pickAndLoadSvg(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
      withData: kIsWeb, // Important: ensure bytes are loaded on web
    );

    if (result != null && result.files.single != null) {
      String svgString;

      // On web, use bytes
      if (kIsWeb) {
        final fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          throw Exception('Failed to read file bytes on web');
        }
        svgString = String.fromCharCodes(fileBytes);
      }
      // On mobile (Android/iOS), read from file path
      else {
        final path = result.files.single.path;
        if (path == null) {
          throw Exception('Failed to get file path');
        }
        final file = File(path);
        svgString = await file.readAsString();
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SvgMapScreen(svgString: svgString),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading file: $e')),
      );
    }
  }
}
