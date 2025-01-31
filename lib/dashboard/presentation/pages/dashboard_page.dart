import 'package:flutter/material.dart';
import 'package:gudshow/dashboard/presentation/pages/editor_page.dart';
import 'package:gudshow/split/trimmer_with_split.dart';

class EditorDashBoardPage extends StatefulWidget {
  const EditorDashBoardPage({super.key});

  @override
  State<EditorDashBoardPage> createState() => _EditorDashBoardPageState();
}

class _EditorDashBoardPageState extends State<EditorDashBoardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Gudshow Poc'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints;
          return SizedBox(
            width: size.maxWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ContusPlayerScreen();
                        },
                      ),
                    );
                  },
                  child: Text('Video Editor'),
                ),
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (context) {
                //           return TrimmerAndSplit(
                //             builder: (context, splitMethod) {},
                //           );
                //         },
                //       ),
                //     );
                //   },
                //   child: Text('Rough'),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
