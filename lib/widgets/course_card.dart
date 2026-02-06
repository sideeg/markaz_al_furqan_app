import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/course.dart';
import 'progress_chip.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showEnrollmentStatus;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showEnrollmentStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height to prevent unbounded constraints
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 300,
      ),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important fix
            children: [
              // Course Image - Fixed height instead of Expanded
              Container(
                height: 120, // Fixed height
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: course.imagePath != null
                      ? CachedNetworkImage(
                          imageUrl: course.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),

              // Course Info - Fixed padding instead of Expanded
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Important fix
                  children: [
                    // Course Title
                    Text(
                      course.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Course Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.typeDisplayName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getTypeColor(),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom Row
                    Row(
                      children: [
                        // Students Count
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${course.currentStudents}/${course.maxStudents}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Enrollment Status or Registration Status
                        if (showEnrollmentStatus && course.isEnrolled)
                          _buildEnrollmentStatusIcon()
                        else if (!course.isRegistrationOpen)
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.error,
                          )
                        else if (!course.canEnroll)
                          Icon(
                            Icons.group,
                            size: 16,
                            color: AppColors.warning,
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 40,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildEnrollmentStatusIcon() {
    IconData icon;
    Color color;

    switch (course.enrollmentStatus) {
      case 'approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'pending':
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        break;
      case 'completed':
        icon = Icons.emoji_events;
        color = AppColors.secondary;
        break;
      case 'dropped':
        icon = Icons.remove_circle_outline;
        color = AppColors.onSurfaceVariant;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.onSurfaceVariant;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Color _getTypeColor() {
    switch (course.type) {
      case 'online':
        return AppColors.info;
      case 'open':
        return AppColors.success;
      case 'closed':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class CompactCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CompactCourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 56,
            maxHeight: 56,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: course.imagePath != null
                ? CachedNetworkImage(
                    imageUrl: course.imagePath!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.image),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.menu_book_rounded),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.menu_book_rounded),
                  ),
          ),
        ),
        title: Text(
          course.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.typeDisplayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getTypeColor(),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.people_outline,
                  size: 12,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '${course.currentStudents}/${course.maxStudents}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: course.isEnrolled
            ? _buildEnrollmentStatusIcon()
            : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildEnrollmentStatusIcon() {
    IconData icon;
    Color color;

    switch (course.enrollmentStatus) {
      case 'approved':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'pending':
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        break;
      case 'completed':
        icon = Icons.emoji_events;
        color = AppColors.secondary;
        break;
      case 'dropped':
        icon = Icons.remove_circle_outline;
        color = AppColors.onSurfaceVariant;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.onSurfaceVariant;
    }

    return Icon(
      icon,
      size: 20,
      color: color,
    );
  }

  Color _getTypeColor() {
    switch (course.type) {
      case 'online':
        return AppColors.info;
      case 'open':
        return AppColors.success;
      case 'closed':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
