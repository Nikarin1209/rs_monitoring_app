import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/doctor_models.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../state/profile_provider.dart';
import '../widgets/nl_widgets.dart';
import 'chat_screen.dart';

class PatientCareScreen extends StatefulWidget {
  const PatientCareScreen({super.key});

  @override
  State<PatientCareScreen> createState() => _PatientCareScreenState();
}

class _PatientCareScreenState extends State<PatientCareScreen> {
  DoctorListItem? _doctor;
  TreatmentPlan? _plan;
  List<AppNotification> _notifications = [];
  int _unreadMessages = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        profile.doctorId == null
            ? Future<DoctorListItem?>.value(null)
            : SupabaseService.getDoctorListItem(profile.doctorId!),
        SupabaseService.getPatientActiveTreatmentPlan(profile.id),
        SupabaseService.getNotifications(),
        profile.doctorId == null
            ? Future<int>.value(0)
            : SupabaseService.getUnreadChatCount(profile.doctorId!),
      ]);
      if (!mounted) return;
      setState(() {
        _doctor = results[0] as DoctorListItem?;
        _plan = results[1] as TreatmentPlan?;
        _notifications = results[2] as List<AppNotification>;
        _unreadMessages = results[3] as int;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Не указано';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  Future<void> _openChat(UserProfile profile) async {
    final doctor = _doctor;
    if (doctor == null || profile.doctorId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: profile.doctorId!,
          otherUserName: doctor.name,
          subtitle: doctor.specialty.isEmpty
              ? 'Лечащий врач'
              : doctor.specialty,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _markAllRead() async {
    await SupabaseService.markAllNotificationsRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      backgroundColor: NLColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: NLColors.accent,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              const NLTopBar(leading: NLBackBtn(), title: 'Врач и лечение'),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: NLColors.accent),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DoctorCard(
                        doctor: _doctor,
                        unreadMessages: _unreadMessages,
                        onChat: profile == null
                            ? null
                            : () => _openChat(profile),
                      ),
                      const NLSectionTitle('Подобранное лечение'),
                      _TreatmentCard(plan: _plan, date: _date),
                      const NLSectionTitle('Уведомления'),
                      if (_notifications.any((n) => n.unread))
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _markAllRead,
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Отметить прочитанными',
                                style: TextStyle(
                                  color: NLColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_notifications.isEmpty)
                        const NLCard(
                          child: Text(
                            'Пока нет уведомлений от врача.',
                            style: TextStyle(color: NLColors.muted),
                          ),
                        )
                      else
                        NLList(
                          children: [
                            for (var i = 0; i < _notifications.length; i++)
                              GestureDetector(
                                onTap: () async {
                                  if (_notifications[i].unread) {
                                    await SupabaseService.markNotificationRead(
                                      _notifications[i].id,
                                    );
                                    await _load();
                                  }
                                },
                                child: _NotificationRow(
                                  notification: _notifications[i],
                                  last: i == _notifications.length - 1,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientCarePreviewCard extends StatefulWidget {
  const PatientCarePreviewCard({super.key});

  @override
  State<PatientCarePreviewCard> createState() => _PatientCarePreviewCardState();
}

class _PatientCarePreviewCardState extends State<PatientCarePreviewCard> {
  DoctorListItem? _doctor;
  TreatmentPlan? _plan;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;
    final results = await Future.wait([
      profile.doctorId == null
          ? Future<DoctorListItem?>.value(null)
          : SupabaseService.getDoctorListItem(profile.doctorId!),
      SupabaseService.getPatientActiveTreatmentPlan(profile.id),
      SupabaseService.getUnreadNotificationCount(),
      profile.doctorId == null
          ? Future<int>.value(0)
          : SupabaseService.getUnreadChatCount(profile.doctorId!),
    ]);
    if (!mounted) return;
    setState(() {
      _doctor = results[0] as DoctorListItem?;
      _plan = results[1] as TreatmentPlan?;
      _unreadNotifications = results[2] as int;
      _unreadMessages = results[3] as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _unreadNotifications + _unreadMessages;
    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PatientCareScreen()));
        if (mounted) _load();
      },
      child: NLCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: totalUnread > 0 ? NLColors.roseSoft : NLColors.skySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                totalUnread > 0
                    ? Icons.notifications_active_outlined
                    : Icons.medical_services_outlined,
                color: totalUnread > 0 ? NLColors.bad : NLColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _doctor == null ? 'Лечащий врач не выбран' : _doctor!.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: NLColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _plan == null
                        ? 'Назначений пока нет'
                        : 'Лечение: ${_plan!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: NLColors.muted),
                  ),
                ],
              ),
            ),
            if (totalUnread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: NLColors.roseSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalUnread',
                  style: const TextStyle(
                    color: NLColors.bad,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: NLColors.muted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorListItem? doctor;
  final int unreadMessages;
  final VoidCallback? onChat;

  const _DoctorCard({
    required this.doctor,
    required this.unreadMessages,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    if (doctor == null) {
      return const NLCard(
        child: Text(
          'Выберите лечащего врача в профиле, чтобы здесь появился чат и назначения.',
          style: TextStyle(color: NLColors.muted),
        ),
      );
    }

    return NLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctor!.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NLColors.ink,
            ),
          ),
          if (doctor!.specialty.isNotEmpty ||
              doctor!.clinicName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (doctor!.specialty.isNotEmpty) doctor!.specialty,
                if (doctor!.clinicName.isNotEmpty) doctor!.clinicName,
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: NLColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          NLButton(
            label: unreadMessages > 0
                ? 'Чат · $unreadMessages новых'
                : 'Написать врачу',
            full: true,
            icon: const Icon(
              Icons.forum_outlined,
              size: 18,
              color: Colors.white,
            ),
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final TreatmentPlan? plan;
  final String Function(DateTime?) date;

  const _TreatmentCard({required this.plan, required this.date});

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return const NLCard(
        child: Text(
          'Врач пока не добавил план лечения.',
          style: TextStyle(color: NLColors.muted),
        ),
      );
    }

    return NLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan!.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: NLColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (plan!.medication.isNotEmpty)
            _Line(label: 'Терапия', value: plan!.medication),
          if (plan!.dosage.isNotEmpty)
            _Line(label: 'Дозировка', value: plan!.dosage),
          if (plan!.recommendations.isNotEmpty)
            _Line(label: 'Рекомендации', value: plan!.recommendations),
          _Line(label: 'Следующий визит', value: date(plan!.nextVisitAt)),
          if (plan!.contactNote.isNotEmpty)
            _Line(label: 'Заметка', value: plan!.contactNote),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final bool last;

  const _NotificationRow({required this.notification, required this.last});

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return NLListRow(
      icon: Icon(
        notification.type == 'visit_scheduled'
            ? Icons.event_available_outlined
            : Icons.medication_outlined,
        size: 16,
        color: notification.unread ? NLColors.bad : NLColors.accent,
      ),
      iconBg: notification.unread ? NLColors.roseSoft : NLColors.accentSoft,
      title: notification.title,
      sub: '${notification.body} · ${_date(notification.createdAt)}',
      right: notification.unread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: NLColors.bad,
                shape: BoxShape.circle,
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              color: NLColors.muted,
              size: 20,
            ),
      last: last,
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: NLColors.ink2,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
