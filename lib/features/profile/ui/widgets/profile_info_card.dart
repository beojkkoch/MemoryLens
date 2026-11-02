import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// White card with the email used to sign in, the city and the profession.
class ProfileInfoCard extends StatelessWidget {
  final String email;
  final String city;
  final String profession;

  const ProfileInfoCard({
    super.key,
    required this.email,
    required this.city,
    required this.profession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.mail_outline, label: 'Correo', value: email),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ciudad',
            value: city,
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.work_outline,
            label: 'Profesión',
            value: profession,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
