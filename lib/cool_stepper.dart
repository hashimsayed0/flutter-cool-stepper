library cool_stepper;

import 'package:another_flushbar/flushbar.dart';
import 'package:cool_stepper/src/models/cool_step.dart';
import 'package:cool_stepper/src/models/cool_stepper_config.dart';
import 'package:cool_stepper/src/widgets/cool_stepper_view.dart';
import 'package:flutter/material.dart';

export 'package:cool_stepper/src/models/cool_step.dart';
export 'package:cool_stepper/src/models/cool_stepper_config.dart';

/// CoolStepper
class CoolStepper extends StatefulWidget {
  /// The steps of the stepper whose titles, subtitles, content always get shown.
  ///
  /// The length of [steps] must not change.
  final List<CoolStep> steps;

  /// Actions to take when the final stepper is passed
  final VoidCallback onCompleted;

  /// Padding for the content inside the stepper
  final EdgeInsetsGeometry contentPadding;

  /// CoolStepper config
  final CoolStepperConfig config;

  /// This determines if or not a snackbar displays your error message if validation fails
  ///
  /// default is false
  final bool showErrorSnackbar;

  const CoolStepper({
    Key? key,
    required this.steps,
    required this.onCompleted,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.config = const CoolStepperConfig(),
    this.showErrorSnackbar = false,
  }) : super(key: key);

  @override
  State<CoolStepper> createState() => _CoolStepperState();
}

class _CoolStepperState extends State<CoolStepper> {
  PageController? _controller = PageController();

  int currentStep = 0;

  @override
  void dispose() {
    _controller!.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void>? switchToPage(int page) {
    _controller!.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    return null;
  }

  bool _isFirst(int index) {
    return index == 0;
  }

  bool _isLast(int index) {
    return widget.steps.length - 1 == index;
  }

  Future<void> onStepNext() async {
    // final context
    final validation = await widget.steps[currentStep].validation!();

    /// [validation] is null, no validation rule
    if (validation == null) {
      if (!_isLast(currentStep)) {
        setState(() {
          currentStep++;
        });

        if (mounted) FocusScope.of(context).unfocus();

        await switchToPage(currentStep);
      } else {
        widget.onCompleted();
      }
    } else {
      if (!mounted) return;

      /// [showErrorSnackbar] is true, Show error snackbar rule
      if (widget.showErrorSnackbar) {
        final flush = Flushbar(
          message: validation,
          flushbarStyle: FlushbarStyle.FLOATING,
          margin: const EdgeInsets.all(8.0),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          icon: Icon(
            Icons.info_outline,
            size: 28.0,
            color: Theme.of(context).primaryColor,
          ),
          duration: const Duration(seconds: 2),
          leftBarIndicatorColor: Theme.of(context).primaryColor,
        );
        await flush.show(context);

        // final snackBar = SnackBar(content: Text(validation));
        // ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void onStepBack() {
    if (!_isFirst(currentStep)) {
      setState(() {
        currentStep--;
      });
      switchToPage(currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: widget.steps.map((step) {
          return CoolStepperView(
            step: step,
            contentPadding: widget.contentPadding,
            config: widget.config,
          );
        }).toList(),
      ),
    );

    final counter = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${currentStep + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "/  ${widget.steps.length}",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    String getNextLabel() {
      String nextLabel;
      if (_isLast(currentStep)) {
        nextLabel = widget.config.finalText ?? 'FINISH';
      } else {
        if (widget.config.nextTextList != null) {
          nextLabel = widget.config.nextTextList![currentStep];
        } else {
          nextLabel = widget.config.nextText ?? 'NEXT';
        }
      }
      return nextLabel;
    }

    String getPrevLabel() {
      String backLabel;
      if (_isFirst(currentStep)) {
        backLabel = '';
      } else {
        if (widget.config.backTextList != null) {
          backLabel = widget.config.backTextList![currentStep - 1];
        } else {
          backLabel = widget.config.backText ?? 'PREV';
        }
      }
      return backLabel;
    }

    final buttons = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Visibility(
              visible: !_isFirst(currentStep),
              maintainSize: false,
              maintainAnimation: true,
              maintainState: true,
              child: ElevatedButton.icon(
                onPressed: onStepBack,
                icon: Icon(Icons.arrow_back, size: 18),
                label: Text(
                  getPrevLabel(),
                  style: widget.config.backButtonTextStyle ??
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: counter,
          ),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: widget.config.isNextButtonLoading ? null : onStepNext,
              icon: widget.config.isNextButtonLoading
                  ? const SizedBox.shrink()
                  : Icon(
                      _isLast(currentStep) ? Icons.check : Icons.arrow_forward,
                      size: 18,
                      color: _isLast(currentStep)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              label: widget.config.isNextButtonLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isLast(currentStep)
                              ? Theme.of(context).colorScheme.onTertiary
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      getNextLabel(),
                      style: widget.config.nextButtonTextStyle ??
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _isLast(currentStep)
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                              ),
                    ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.config.isNextButtonLoading ? 20 : 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _isLast(currentStep)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: _isLast(currentStep)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [content, buttons],
    );
  }
}