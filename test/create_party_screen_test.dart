import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queue_up_india/core/constants/app_options.dart';
import 'package:queue_up_india/features/party/bloc/party_bloc.dart';
import 'package:queue_up_india/features/party/data/repositories/mock_party_repository.dart';
import 'package:queue_up_india/features/party/presentation/view/create_party_screen.dart';
import 'package:queue_up_india/features/party/viewmodel/party_view_model.dart';

void main() {
  testWidgets('create party screen builds without runtime exception', (
    WidgetTester tester,
  ) async {
    final partyBloc = PartyBloc(
      partyViewModel: PartyViewModel(partyRepository: MockPartyRepository()),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            home: BlocProvider<PartyBloc>.value(
              value: partyBloc,
              child: const CreatePartyScreen(gameId: AppOptions.valorantId),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
