// ignore_for_file: deprecated_member_use

import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact, rounded search TextField designed for AppBar/SliverAppBar flexibleSpace.
/// It forwards nearly all TextField parameters while providing sensible defaults
/// for search UX (search prefix icon, animated clear button, filled/rounded border).
///
/// Use via the [extField(...)] function below.
class SearchAppBarTextField extends StatefulWidget {
  final Object? groupId;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final UndoHistoryController? undoController;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final ToolbarOptions? toolbarOptions;
  final bool? showCursor;
  final bool autofocus;
  final WidgetStatesController? statesController;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final void Function(String, Map<String, dynamic>)? onAppPrivateCommand;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final bool? ignorePointers;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final bool? cursorOpacityAnimates;
  final Color? cursorColor;
  final Color? cursorErrorColor;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final void Function()? onTap;
  final bool onTapAlwaysCalled;
  final void Function(PointerDownEvent)? onTapOutside;
  final void Function(PointerUpEvent)? onTapUpOutside;
  final MouseCursor? mouseCursor;
  final Widget? Function(
    BuildContext, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  })?
  buildCounter;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final ContentInsertionConfiguration? contentInsertionConfiguration;
  final Clip clipBehavior;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool stylusHandwritingEnabled;
  final bool enableIMEPersonalizedLearning;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final bool canRequestFocus;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;

  const SearchAppBarTextField({
    super.key,
    this.groupId,
    this.controller,
    this.focusNode,
    this.undoController,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.toolbarOptions,
    this.showCursor,
    this.autofocus = false,
    this.statesController,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.ignorePointers,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates,
    this.cursorColor,
    this.cursorErrorColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.onTapAlwaysCalled = false,
    this.onTapOutside,
    this.onTapUpOutside,
    this.mouseCursor,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.contentInsertionConfiguration,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scribbleEnabled = true,
    this.stylusHandwritingEnabled =
        EditableText.defaultStylusHandwritingEnabled,
    this.enableIMEPersonalizedLearning = true,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
  });

  @override
  State<SearchAppBarTextField> createState() => SearchAppBarTextFieldState();
}

class SearchAppBarTextFieldState extends State<SearchAppBarTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SearchAppBarTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        // dispose old owned controller
        _controller.dispose();
      }
      // adopt new
      final owns = widget.controller == null;
      if (owns) {
        // Create a new controller mirroring old text to keep UI stable
        final newController = TextEditingController(text: _controller.text);
        _controller = newController;
      } else {
        _controller = widget.controller!;
      }
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _mergeDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final defaultDecoration = InputDecoration(
      hintText: 'Search',
      isDense: true,
      filled: true,
      fillColor: theme.brightness == Brightness.dark
          ? scheme.surface.withValues(alpha:0.24)
          : scheme.surfaceContainerHighest.withValues(alpha:0.72),
      prefixIcon: const Icon(Icons.search_rounded),
      // Animated clear button; if a custom suffixIcon is supplied by the caller, we won't override it.
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, child) {
          final hasText = value.text.isNotEmpty;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          );
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: scheme.primary.withValues(alpha:0.32),
          width: 1.2,
        ),
      ),
    );

    // If the caller passed a decoration, we respect their properties and fallback to defaults for any nulls.
    final d = widget.decoration ?? const InputDecoration();
    return defaultDecoration.copyWith(
      hintText: d.hintText ?? defaultDecoration.hintText,
      hintStyle: d.hintStyle ?? defaultDecoration.hintStyle,
      isDense: d.isDense ?? defaultDecoration.isDense,
      filled: d.filled ?? defaultDecoration.filled,
      fillColor: d.fillColor ?? defaultDecoration.fillColor,
      prefixIcon: d.prefixIcon ?? defaultDecoration.prefixIcon,
      suffixIcon: d.suffixIcon ?? defaultDecoration.suffixIcon,
      contentPadding: d.contentPadding ?? defaultDecoration.contentPadding,
      border: d.border ?? defaultDecoration.border,
      enabledBorder: d.enabledBorder ?? defaultDecoration.enabledBorder,
      focusedBorder: d.focusedBorder ?? defaultDecoration.focusedBorder,
      errorBorder: d.errorBorder ?? defaultDecoration.errorBorder,
      focusedErrorBorder:
          d.focusedErrorBorder ?? defaultDecoration.focusedErrorBorder,
      helperText: d.helperText,
      helperStyle: d.helperStyle,
      counterText: d.counterText,
      counterStyle: d.counterStyle,
      labelText: d.labelText,
      labelStyle: d.labelStyle,
      prefix: d.prefix,
      prefixStyle: d.prefixStyle,
      suffix: d.suffix,
      suffixStyle: d.suffixStyle,
      prefixIconColor: d.prefixIconColor,
      suffixIconColor: d.suffixIconColor,
      constraints: d.constraints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _mergeDecoration(context);

    // Wrapper to keep the field visually compact and centered in app bar areas.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 44),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        undoController: widget.undoController,
        decoration: decoration,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        textInputAction: widget.textInputAction ?? TextInputAction.search,
        textCapitalization: widget.textCapitalization,
        style: widget.style,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        textDirection: widget.textDirection,
        readOnly: widget.readOnly,
        toolbarOptions: widget.toolbarOptions,
        showCursor: widget.showCursor,
        autofocus: widget.autofocus,
        statesController: widget.statesController,
        obscuringCharacter: widget.obscuringCharacter,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        smartDashesType: widget.smartDashesType,
        smartQuotesType: widget.smartQuotesType,
        enableSuggestions: widget.enableSuggestions,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        maxLength: widget.maxLength,
        maxLengthEnforcement: widget.maxLengthEnforcement,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        onSubmitted: widget.onSubmitted,
        onAppPrivateCommand: widget.onAppPrivateCommand,
        inputFormatters: widget.inputFormatters,
        enabled: widget.enabled,
        ignorePointers: widget.ignorePointers,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorRadius: widget.cursorRadius,
        cursorOpacityAnimates: widget.cursorOpacityAnimates,
        cursorColor: widget.cursorColor,
        cursorErrorColor: widget.cursorErrorColor,
        selectionHeightStyle: widget.selectionHeightStyle,
        selectionWidthStyle: widget.selectionWidthStyle,
        keyboardAppearance: widget.keyboardAppearance,
        scrollPadding: widget.scrollPadding,
        dragStartBehavior: widget.dragStartBehavior,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        selectionControls: widget.selectionControls,
        onTap: widget.onTap,
        onTapAlwaysCalled: widget.onTapAlwaysCalled,
        onTapOutside: widget.onTapOutside,
        onTapUpOutside: widget.onTapUpOutside,
        mouseCursor: widget.mouseCursor,
        buildCounter: widget.buildCounter,
        scrollController: widget.scrollController,
        scrollPhysics: widget.scrollPhysics,
        autofillHints: widget.autofillHints,
        contentInsertionConfiguration: widget.contentInsertionConfiguration,
        clipBehavior: widget.clipBehavior,
        restorationId: widget.restorationId,
        scribbleEnabled: widget.scribbleEnabled,
        stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
        enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
        contextMenuBuilder: widget.contextMenuBuilder,
        canRequestFocus: widget.canRequestFocus,
        spellCheckConfiguration: widget.spellCheckConfiguration,
        magnifierConfiguration: widget.magnifierConfiguration,
      ),
    );
  }
}

/// Public function to build the search field with your full parameter set.
Widget extField({
  Key? key,
  Object? groupId,
  TextEditingController? controller,
  FocusNode? focusNode,
  UndoHistoryController? undoController,
  InputDecoration? decoration = const InputDecoration(),
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  TextCapitalization textCapitalization = TextCapitalization.none,
  TextStyle? style,
  StrutStyle? strutStyle,
  TextAlign textAlign = TextAlign.start,
  TextAlignVertical? textAlignVertical,
  TextDirection? textDirection,
  bool readOnly = false,
  ToolbarOptions? toolbarOptions,
  bool? showCursor,
  bool autofocus = false,
  WidgetStatesController? statesController,
  String obscuringCharacter = '•',
  bool obscureText = false,
  bool autocorrect = true,
  SmartDashesType? smartDashesType,
  SmartQuotesType? smartQuotesType,
  bool enableSuggestions = true,
  int? maxLines = 1,
  int? minLines,
  bool expands = false,
  int? maxLength,
  MaxLengthEnforcement? maxLengthEnforcement,
  void Function(String)? onChanged,
  void Function()? onEditingComplete,
  void Function(String)? onSubmitted,
  void Function(String, Map<String, dynamic>)? onAppPrivateCommand,
  List<TextInputFormatter>? inputFormatters,
  bool? enabled,
  bool? ignorePointers,
  double cursorWidth = 2.0,
  double? cursorHeight,
  Radius? cursorRadius,
  bool? cursorOpacityAnimates,
  Color? cursorColor,
  Color? cursorErrorColor,
  ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
  ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
  Brightness? keyboardAppearance,
  EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
  DragStartBehavior dragStartBehavior = DragStartBehavior.start,
  bool? enableInteractiveSelection,
  TextSelectionControls? selectionControls,
  void Function()? onTap,
  bool onTapAlwaysCalled = false,
  void Function(PointerDownEvent)? onTapOutside,
  void Function(PointerUpEvent)? onTapUpOutside,
  MouseCursor? mouseCursor,
  Widget? Function(
    BuildContext, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  })?
  buildCounter,
  ScrollController? scrollController,
  ScrollPhysics? scrollPhysics,
  Iterable<String>? autofillHints = const <String>[],
  ContentInsertionConfiguration? contentInsertionConfiguration,
  Clip clipBehavior = Clip.hardEdge,
  String? restorationId,
  bool scribbleEnabled = true,
  bool stylusHandwritingEnabled = EditableText.defaultStylusHandwritingEnabled,
  bool enableIMEPersonalizedLearning = true,
  Widget Function(BuildContext, EditableTextState)? contextMenuBuilder,
  bool canRequestFocus = true,
  SpellCheckConfiguration? spellCheckConfiguration,
  TextMagnifierConfiguration? magnifierConfiguration,
}) {
  return SearchAppBarTextField(
    key: key,
    groupId: groupId,
    controller: controller,
    focusNode: focusNode,
    undoController: undoController,
    decoration: decoration,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textAlignVertical: textAlignVertical,
    textDirection: textDirection,
    readOnly: readOnly,
    toolbarOptions: toolbarOptions,
    showCursor: showCursor,
    autofocus: autofocus,
    statesController: statesController,
    obscuringCharacter: obscuringCharacter,
    obscureText: obscureText,
    autocorrect: autocorrect,
    smartDashesType: smartDashesType,
    smartQuotesType: smartQuotesType,
    enableSuggestions: enableSuggestions,
    maxLines: maxLines,
    minLines: minLines,
    expands: expands,
    maxLength: maxLength,
    maxLengthEnforcement: maxLengthEnforcement,
    onChanged: onChanged,
    onEditingComplete: onEditingComplete,
    onSubmitted: onSubmitted,
    onAppPrivateCommand: onAppPrivateCommand,
    inputFormatters: inputFormatters,
    enabled: enabled,
    ignorePointers: ignorePointers,
    cursorWidth: cursorWidth,
    cursorHeight: cursorHeight,
    cursorRadius: cursorRadius,
    cursorOpacityAnimates: cursorOpacityAnimates,
    cursorColor: cursorColor,
    cursorErrorColor: cursorErrorColor,
    selectionHeightStyle: selectionHeightStyle,
    selectionWidthStyle: selectionWidthStyle,
    keyboardAppearance: keyboardAppearance,
    scrollPadding: scrollPadding,
    dragStartBehavior: dragStartBehavior,
    enableInteractiveSelection: enableInteractiveSelection,
    selectionControls: selectionControls,
    onTap: onTap,
    onTapAlwaysCalled: onTapAlwaysCalled,
    onTapOutside: onTapOutside,
    onTapUpOutside: onTapUpOutside,
    mouseCursor: mouseCursor,
    buildCounter: buildCounter,
    scrollController: scrollController,
    scrollPhysics: scrollPhysics,
    autofillHints: autofillHints,
    contentInsertionConfiguration: contentInsertionConfiguration,
    clipBehavior: clipBehavior,
    restorationId: restorationId,
    scribbleEnabled: scribbleEnabled,
    stylusHandwritingEnabled: stylusHandwritingEnabled,
    enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
    contextMenuBuilder: contextMenuBuilder,
    canRequestFocus: canRequestFocus,
    spellCheckConfiguration: spellCheckConfiguration,
    magnifierConfiguration: magnifierConfiguration,
  );
}
