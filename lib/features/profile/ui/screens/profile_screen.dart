import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_bloc.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_event.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_state.dart';
import 'package:memorylens/features/profile/ui/widgets/profile_header_card.dart';
import 'package:memorylens/features/profile/ui/widgets/profile_info_card.dart';
import 'package:memorylens/features/profile/ui/widgets/profile_interests_card.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Summary of the signed in person. Needs a ProfileBloc above it.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current.status == ProfileStatus.signedOut &&
          previous.status != ProfileStatus.signedOut,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const MemoryLensAppBar(title: 'Mi perfil'),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final profile = state.profile;
            if (state.status == ProfileStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ProfileStatus.failure || profile == null) {
              return _FailureView(
                message: state.errorMessage ?? 'No se pudo cargar el perfil',
              );
            }
            return _ProfileContent(
              profile: profile,
              signingOut: state.signingOut,
              errorMessage: state.errorMessage,
            );
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Profile profile;
  final bool signingOut;
  final String? errorMessage;

  const _ProfileContent({
    required this.profile,
    required this.signingOut,
    required this.errorMessage,
  });

  String get _subtitle {
    return [
      profile.profession,
      profile.city,
    ].where((p) => p.trim().isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ProfileHeaderCard(name: profile.fullName, subtitle: _subtitle),
        const SizedBox(height: 16),
        ProfileInfoCard(
          email: profile.email,
          city: profile.city,
          profession: profile.profession,
        ),
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 16),
          ProfileInterestsCard(
            names: [for (final interest in profile.interests) interest.name],
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          ErrorMessage(message: errorMessage!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: signingOut
                ? null
                : () => context.read<ProfileBloc>().add(
                    ProfileSignOutRequested(),
                  ),
            icon: signingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;

  const _FailureView({required this.message});

  @override
  Widget build(BuildContext context) {
    return ErrorRetryView(
      message: message,
      onRetry: () => context.read<ProfileBloc>().add(ProfileRequested()),
      actions: [
        TextButton(
          onPressed: () =>
              context.read<ProfileBloc>().add(ProfileSignOutRequested()),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
