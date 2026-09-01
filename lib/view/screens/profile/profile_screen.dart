import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:wio_pharmacy/view/screens/authentication/login_screen.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';
import 'package:wio_pharmacy/viewmodel/profile/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _viewModel = ProfileViewModel();
  NavigationViewModel? _navVM;
  int _lastLoadedIndex = -1;
  static const _tabIndex =
      4; // adjust to ProfileScreen's actual position in _screens

  static const navy = Color(0xFF0E1B33);
  static const mint = Color(0xFF17A673);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navVM?.removeListener(_onNavChanged);
    _navVM = context.read<NavigationViewModel>();
    _navVM!.addListener(_onNavChanged);
    _onNavChanged();
  }

  void _onNavChanged() {
    if (_navVM!.selectedIndex == _tabIndex && _lastLoadedIndex != _tabIndex) {
      _lastLoadedIndex = _tabIndex;
      _viewModel.load();
    } else if (_navVM!.selectedIndex != _tabIndex) {
      _lastLoadedIndex = -1;
    }
  }

  @override
  void dispose() {
    _navVM?.removeListener(_onNavChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeBytes = await file.length();
    const maxBytes =
        5 * 1024 * 1024; // adjust to match PROFILE_IMAGE_MAX_BYTES on backend
    if (sizeBytes > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too large. Please choose a smaller file.'),
          ),
        );
      }
      return;
    }
    await _viewModel.uploadLogo(file);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutConfirmSheet(),
    );
    if (confirmed == true) {
      await _viewModel.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pharmacy Profile',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!vm.isOwner)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Only the pharmacy owner can edit this profile. You can view it, but changes won\'t save.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              _brandingCard(vm),
              const SizedBox(height: 16),
              _contactCard(vm),
              const SizedBox(height: 16),
              _regulatoryCard(vm),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: vm.hasChanges ? vm.discardChanges : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Discard',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (vm.isOwner && !vm.isSaving) ? () => vm.save() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mint,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          vm.isSaving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _brandingCard(ProfileViewModel vm) {
    return _card(
      title: 'Branding & Identity',
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: vm.isUploadingLogo ? null : _pickLogo,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: mint.withOpacity(0.25), width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                    vm.isUploadingLogo
                        ? const Center(child: CircularProgressIndicator())
                        : _logoContent(vm),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to change store logo.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          _textField(
            'Store Name',
            vm.formData.name,
            (v) => vm.updateField(name: v),
            enabled: vm.isOwner,
          ),
          _textField(
            'Tagline',
            vm.formData.tagline,
            (v) => vm.updateField(tagline: v),
            hint: 'e.g. Your trusted partner in care.',
            enabled: vm.isOwner,
          ),
          _textField(
            'Store Description',
            vm.formData.description,
            (v) => vm.updateField(description: v),
            maxLines: 3,
            hint: 'A brief summary for customer receipts...',
            enabled: vm.isOwner,
          ),
        ],
      ),
    );
  }

  Widget _logoContent(ProfileViewModel vm) {
    if (vm.logoDisplayPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.file(File(vm.logoDisplayPath!), fit: BoxFit.cover),
      );
    }
    if (vm.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.network(
          vm.logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _uploadPlaceholder(),
        ),
      );
    }
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_outlined, size: 28, color: Colors.black38),
        SizedBox(height: 6),
        Text(
          'Upload Logo',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    ),
  );

  Widget _contactCard(ProfileViewModel vm) {
    return _card(
      title: 'Contact Information',
      child: Column(
        children: [
          _textField(
            'Support Email',
            vm.formData.email,
            (v) => vm.updateField(email: v),
            keyboardType: TextInputType.emailAddress,
            enabled: vm.isOwner,
          ),
          _textField(
            'Store Hotline',
            vm.formData.phone,
            (v) => vm.updateField(phone: v),
            keyboardType: TextInputType.phone,
            enabled: vm.isOwner,
          ),
          _textField(
            'Physical Address',
            vm.formData.address,
            (v) => vm.updateField(address: v),
            maxLines: 3,
            enabled: vm.isOwner,
          ),
        ],
      ),
    );
  }

  Widget _regulatoryCard(ProfileViewModel vm) {
    return _card(
      title: 'Regulatory',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _textField(
            'Drug License #',
            vm.formData.licenseNo,
            (v) => vm.updateField(licenseNo: v),
            monospace: true,
            enabled: vm.isOwner,
          ),
          _textField(
            'Tax ID / BIN',
            vm.formData.taxBin,
            (v) => vm.updateField(taxBin: v),
            monospace: true,
            enabled: vm.isOwner,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Certificate',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Verify ISO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mint.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: mint, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool monospace = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 13,
          fontFamily: monospace ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _LogoutConfirmSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text(
            'Log Out?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "You'll need to sign in again to access your pharmacy dashboard.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
