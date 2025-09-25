import 'dart:html' as html;
import 'dart:convert';

void downloadSvg(String svgContent) {
  final bytes = utf8.encode(svgContent);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'muscles.svg')
    ..click();
  html.Url.revokeObjectUrl(url);
}
