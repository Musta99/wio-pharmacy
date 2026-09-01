import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wio_pharmacy/core/services/token_services.dart';
import 'package:wio_pharmacy/models/pharmacy_wallet.dart';
import 'package:wio_pharmacy/services/profile_services.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileService? service})
    : _service = service ?? ProfileService();

  final ProfileService _service;
  bool _disposed = false;
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isUploadingLogo = false;
  bool get isUploadingLogo => _isUploadingLogo;

  bool _isOwner = true;
  bool get isOwner => _isOwner;

  PharmacyProfile _loaded = PharmacyProfile.empty;
  PharmacyProfile _formData = PharmacyProfile.empty;
  PharmacyProfile get formData => _formData;

  /// Local file path shown immediately while an upload is in flight, before
  /// the server URL is known — mirrors web's local blob: preview.
  String? _localLogoPreviewPath;
  String? get logoDisplayPath => _localLogoPreviewPath;
  String get logoUrl => _formData.logoUrl;

  bool get hasChanges =>
      _formData.name != _loaded.name ||
      _formData.tagline != _loaded.tagline ||
      _formData.description != _loaded.description ||
      _formData.email != _loaded.email ||
      _formData.phone != _loaded.phone ||
      _formData.address != _loaded.address ||
      _formData.licenseNo != _loaded.licenseNo ||
      _formData.taxBin != _loaded.taxBin;

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final (profile, isOwner) = await _service.getProfile();
      _loaded = profile;
      _formData = profile;
      _isOwner = isOwner;
      _localLogoPreviewPath = null;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void updateField({
    String? name,
    String? tagline,
    String? description,
    String? email,
    String? phone,
    String? address,
    String? licenseNo,
    String? taxBin,
  }) {
    _formData = _formData.copyWith(
      name: name,
      tagline: tagline,
      description: description,
      email: email,
      phone: phone,
      address: address,
      licenseNo: licenseNo,
      taxBin: taxBin,
    );
    _safeNotify();
  }

  void discardChanges() {
    _formData = _loaded;
    _localLogoPreviewPath = null;
    _safeNotify();
  }

  Future<bool> save() async {
    _isSaving = true;
    _safeNotify();
    try {
      await _service.updateProfile(_formData);
      _loaded = _formData;
      Fluttertoast.showToast(
        msg: 'Changes are now live across the WIO network.',
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<void> uploadLogo(File file) async {
    _localLogoPreviewPath = file.path;
    _isUploadingLogo = true;
    _safeNotify();
    try {
      final newUrl = await _service.uploadLogo(file);
      _formData = _formData.copyWith(logoUrl: newUrl);
      _loaded = _loaded.copyWith(logoUrl: newUrl);
      Fluttertoast.showToast(msg: 'Your store logo has been saved.');
    } catch (e) {
      _localLogoPreviewPath = null; // revert to previous remote logoUrl
      Fluttertoast.showToast(msg: '$e');
    } finally {
      _isUploadingLogo = false;
      _safeNotify();
    }
  }

  Future<void> logout() async {
    await TokenService.instance.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
