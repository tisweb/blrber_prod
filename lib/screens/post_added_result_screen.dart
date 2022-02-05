//Imports for pubspec packages
import 'package:flutter/material.dart';

//Imports for Constants
import '../constants.dart';

//Imports for Screens
import '../screens/tabs_screen.dart';

class PostAddedResultScreen extends StatelessWidget {
  final String editPost;
  final String displayType;
  const PostAddedResultScreen({Key key, this.editPost, this.displayType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              displayType == "P"
                  ? RichText(
                      text: const TextSpan(
                        text: 'Your post added successfully!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : RichText(
                      text: const TextSpan(
                        text: 'Your Order created successfully!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              if (displayType == "P")
                RichText(
                  text: const TextSpan(
                    text: 'You will be notified once your post is verified!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton.icon(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    bPrimaryColor,
                  ),
                ),
                onPressed: () {
                  editPost == "true"
                      ? Navigator.of(context).pop()
                      : Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) {
                                return TabsScreen(0);
                              },
                              fullscreenDialog: true),
                        );
                },
                icon: const Icon(Icons.launch),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
