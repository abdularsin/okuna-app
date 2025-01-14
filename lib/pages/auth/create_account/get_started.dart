import 'package:Okuna/services/localization.dart';
import 'package:Okuna/widgets/buttons/button.dart';
import 'package:Okuna/widgets/buttons/success_button.dart';
import 'package:Okuna/widgets/buttons/secondary_button.dart';
import 'package:flutter/material.dart';

class OBAuthGetStartedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var localizationService = LocalizationService.of(context);
    String letsGetStartedText =
        localizationService.auth__create_acc__lets_get_started;
    String welcomeToAlphaText =
        localizationService.auth__create_acc__welcome_to_beta;

    String previousText = localizationService.auth__create_acc__previous;
    String nextText = localizationService.auth__create_acc__next;

    return Scaffold(
      backgroundColor: Color(0xFF151726),
      body: DecoratedBox(
        decoration: _buildGetStartedDecoration(),
        child: Center(
            child: SingleChildScrollView(
                child: _buildLetsGetStarted(getStartedText: letsGetStartedText, welcomeText: welcomeToAlphaText))),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child:
                    _buildPreviousButton(context: context, text: previousText),
              ),
              Expanded(
                  child: _buildNextButton(context: context, text: nextText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetsGetStarted({@required String getStartedText, @required String welcomeText}) {
    return Column(
      children: <Widget>[
        Text(
          '🚀',
          style: TextStyle(fontSize: 45.0, color: Colors.white),
        ),
        const SizedBox(
          height: 20.0,
        ),
        Text(welcomeText,
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        SizedBox(
          height: 20.0,
        ),
        Text(getStartedText,
            style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white))
      ],
    );
  }

  BoxDecoration _buildGetStartedDecoration() {
    return new BoxDecoration(
        image: new DecorationImage(
            image: new AssetImage('assets/images/pixel-universe.jpg'),
            fit: BoxFit.cover));
  }

  Widget _buildNextButton(
      {@required BuildContext context, @required String text}) {
    return OBSuccessButton(
      minWidth: double.infinity,
      size: OBButtonSize.large,
      child: Text(text, style: TextStyle(fontSize: 18.0)),
      onPressed: () {
        Navigator.pushNamed(context, '/auth/name_step');
      },
    );
  }

  Widget _buildPreviousButton(
      {@required BuildContext context, @required String text}) {
    return OBSecondaryButton(
      isFullWidth: true,
      isLarge: true,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          const SizedBox(
            width: 10.0,
          ),
          Text(
            text,
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          )
        ],
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }
}
