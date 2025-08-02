import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karma_palace/src/style/my_button.dart';
import 'package:karma_palace/src/style/palette.dart';
import 'package:provider/provider.dart';

class GameIdDialog extends StatefulWidget {
  final Animation<double> animation;

  const GameIdDialog({
    super.key,
    required this.animation,
  });

  @override
  State<GameIdDialog> createState() => _GameIdDialogState();
}

class _GameIdDialogState extends State<GameIdDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutCubic,
      ),
      child: SimpleDialog(
        title: const Text(
          'Join Game',
          style: TextStyle(
            fontFamily: 'Permanent Marker',
            fontSize: 24,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 20,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Enter game ID to join...',
                    errorText: _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  onSubmitted: (value) {
                    _submitGameId();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MyButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    MyButton(
                      onPressed: _submitGameId,
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitGameId() {
    final gameId = _controller.text.trim();
    if (gameId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a game ID';
      });
      return;
    }
    
    Navigator.pop(context, gameId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 