import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cpf_cnpj_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/phone_input_formatter.dart';
import 'package:air_sync/modules/profile/user_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends GetView<UserProfileController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: context.themeDark,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Atualizar dados',
              onPressed: controller.isLoadingProfile.value ? null : controller.loadProfile,
              icon: controller.isLoadingProfile.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final hasLoaded = controller.hasLoadedProfile.value;
          final isLoading = controller.isLoadingProfile.value;

          if (!hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              RefreshIndicator(
                color: Theme.of(context).colorScheme.secondary,
                onRefresh: controller.loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeader(controller: controller),
                          const SizedBox(height: 24),
                          _SectionCard(
                            title: 'Dados pessoais',
                            subtitle: 'Atualize nome, contato e documento utilizados nas comunicações.',
                            children: [
                              TextField(
                                controller: controller.nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(labelText: 'Nome'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'E-mail'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Telefone'),
                                inputFormatters: [PhoneInputFormatter()],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.documentController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'CPF ou CNPJ'),
                                inputFormatters: [CpfCnpjInputFormatter()],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: Obx(
                                  () => ElevatedButton.icon(
                                    icon: const Icon(Icons.save_outlined),
                                    onPressed: controller.isSavingProfile.value
                                        ? null
                                        : controller.saveProfile,
                                    label: controller.isSavingProfile.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Salvar alterações'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _SectionCard(
                            title: 'Segurança da conta',
                            subtitle: 'Defina uma nova senha forte e mantenha seu acesso protegido.',
                            children: [
                              TextField(
                                controller: controller.currentPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Senha atual'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.newPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Nova senha',
                                  helperText: 'Mínimo de 8 caracteres',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: Obx(
                                  () => ElevatedButton.icon(
                                    icon: const Icon(Icons.lock_reset),
                                    onPressed: controller.isChangingPassword.value
                                        ? null
                                        : controller.changePassword,
                                    label: controller.isChangingPassword.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Atualizar senha'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ao alterar a senha, todas as sessões ativas serão encerradas.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Obx(
                            () => controller.currentUser.value?.isOwner ?? false
                                ? _SectionCard(
                                    title: 'Assinaturas & billing',
                                    subtitle: 'Acesso exclusivo para owners gerenciarem planos, Stripe e overrides.',
                                    children: [
                                      const Text(
                                        'Como Administrador Global você gerencia planos, Stripe e overrides. '
                                        'Acesse o painel de billing para acompanhar cobranças e pagamentos.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.subscriptions_outlined),
                                          onPressed: () => Get.toNamed('/subscriptions'),
                                          label: const Text('Abrir painel de billing'),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isLoading
                      ? const _TopLinearLoader()
                      : const SizedBox(height: 4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TopLinearLoader extends StatelessWidget {
  const _TopLinearLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: .15),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final UserProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      final displayName = _firstNonEmpty([
            user?.name,
            controller.nameController.text,
            user?.email,
          ]) ??
          'Usuário';
      final email = _firstNonEmpty([
            user?.email,
            controller.emailController.text,
          ]) ??
          'Não informado';
      final phone = _firstNonEmpty([user?.phone, controller.phoneController.text]) ?? 'Não informado';
      final document = _firstNonEmpty([user?.cpfOrCnpj, controller.documentController.text]) ?? 'Não informado';
      final isOwner = user?.isOwner ?? false;
      final roleLabel = isOwner
          ? 'Administrador Global (owner)'
          : _firstNonEmpty([user?.role, 'Colaborador'])!;
      final permissionsValue = isOwner ? 'Todas' : (user?.permissions.length ?? 0).toString();
      final planDate = _formatDate(user?.planExpiration);
      final userLevel = user?.userLevel ?? 0;

      if (user == null && controller.nameController.text.trim().isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: const [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Carregando perfil...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }

      final metrics = [
        _ProfileMetricTile(
          icon: Icons.lock_person_outlined,
          label: 'Permissões',
          value: permissionsValue,
        ),
        _ProfileMetricTile(
          icon: Icons.star_border_rounded,
          label: 'Nível',
          value: userLevel.toString(),
        ),
        _ProfileMetricTile(
          icon: Icons.calendar_month_outlined,
          label: 'Plano',
          value: planDate ?? 'Sem data',
        ),
        _ProfileMetricTile(
          icon: Icons.phone_outlined,
          label: 'Telefone',
          value: phone,
        ),
        _ProfileMetricTile(
          icon: Icons.badge_outlined,
          label: 'CPF/CNPJ',
          value: document,
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 560 ? 3 : 2;
          final tileWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
          final isCompact = constraints.maxWidth < 420;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: context.themeDark.withValues(alpha: .4),
                      child: Text(
                        _initials(displayName),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? double.infinity : constraints.maxWidth - 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOwner ? Colors.green.withValues(alpha: .15) : Colors.white12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(color: isOwner ? Colors.greenAccent : Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: tileWidth.clamp(180, 260),
                          child: metric,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ProfileMetricTile extends StatelessWidget {
  const _ProfileMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = Colors.white.withValues(alpha: .08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: context.themeSurface,
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  final result = (first + last).toUpperCase();
  return result.isEmpty ? '?' : result;
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return DateFormat('dd/MM/yyyy').format(date);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

