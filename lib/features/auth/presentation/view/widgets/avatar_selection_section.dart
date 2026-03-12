import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/avatar_selection_grid.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class AvatarSelectionSection extends StatelessWidget {
  const AvatarSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        return AvatarSelectionGrid(
          selectedAvatarUrl: state.data.selectedAvatarUrl,
          title: AppStrings.selectAvatar,
          subtitle: AppStrings.selectAvatarHint,
          onAvatarSelected: (String avatar) {
            context.read<RegistrationBloc>().add(
              RegistrationAvatarSelected(avatarUrl: avatar),
            );
          },
        );
      },
    );
  }
}
