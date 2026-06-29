import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Resolves a stored avatar reference into an [ImageProvider].
///
/// Supports:
///  - `data:image/...;base64,...` data URIs (used for user-uploaded photos so
///    they sync across devices via the backend),
///  - remote `http(s)` URLs (Google account photos),
///  - legacy absolute local file paths (older phone uploads).
///
/// Returns null when there is no usable image so callers can show a fallback
/// icon.
ImageProvider? avatarProvider(String? photoUrl) {
  final value = photoUrl?.trim() ?? '';
  if (value.isEmpty) return null;

  if (value.startsWith('data:image')) {
    try {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) return null;
      final bytes = base64Decode(value.substring(commaIndex + 1));
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  // Legacy: an absolute local file path saved by older app versions. Only
  // usable on the original device while the file still exists.
  final file = File(value);
  if (file.existsSync()) return FileImage(file);
  return null;
}
