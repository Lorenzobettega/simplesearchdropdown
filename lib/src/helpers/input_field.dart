import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatter that accepts any input (default of [InputField.mascara]).
FilteringTextInputFormatter allValues = FilteringTextInputFormatter.allow(
  RegExp('.*'),
);

/// An outlined text field with the package look; exported for apps (the
/// package dialogs use their own field).
class InputField extends StatelessWidget {
  /// Creates an input field bound to [controle].
  const InputField({
    super.key,
    required this.controle,
    this.mascara,
    this.textInputButton = TextInputAction.done,
    this.tipoTeclado = TextInputType.text,
    this.validator,
    this.hint,
    this.width = 200,
    this.oculto = false,
    this.finishFunction,
    this.clear = false,
    this.tapFunction,
    this.lines = 1,
    this.raio = 10,
    this.elevacao = 0.5,
    this.mudeiTextoFunction,
    TextStyle? estilo,
    this.mostrarHint = true,
    this.liberado = true,
    this.alinhamento = TextAlign.start,
    this.disabledColor,
    this.capitalization,
  }) : estilo = estilo ?? const TextStyle(fontSize: 16);
  static const TextStyle _hintLabelStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );
  static const BorderSide _focusedBorderSide = BorderSide(
    color: Color.fromARGB(255, 0, 67, 0),
  );
  static const BorderSide _errorBorderSide = BorderSide(color: Colors.red);

  /// Text controller.
  final TextEditingController controle;

  /// Optional input formatter.
  final TextInputFormatter? mascara;

  /// Keyboard action button.
  final TextInputAction textInputButton;

  /// Keyboard type.
  final TextInputType tipoTeclado;

  /// Form validator.
  final FormFieldValidator<String>? validator;

  /// Hint and label text.
  final String? hint;

  /// Field width.
  final double width;

  /// Obscures the text (passwords).
  final bool oculto;

  /// Called when editing completes.
  final VoidCallback? finishFunction;

  /// Shows a clear button.
  final bool clear;

  /// Called on tap.
  final VoidCallback? tapFunction;

  /// Maximum number of lines.
  final int? lines;

  /// Corner radius.
  final double raio;

  /// Elevation of the surrounding material.
  final double elevacao;

  /// Text style.
  final TextStyle estilo;

  /// Called when the text changes.
  final ValueChanged<String>? mudeiTextoFunction;

  /// Shows the floating label.
  final bool mostrarHint;

  /// Whether the field is enabled.
  final bool liberado;

  /// Text alignment.
  final TextAlign alinhamento;

  /// Border color when disabled.
  final Color? disabledColor;

  /// Text capitalization.
  final TextCapitalization? capitalization;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(raio);
    OutlineInputBorder outline(BorderSide side) =>
        OutlineInputBorder(borderRadius: borderRadius, borderSide: side);
    final OutlineInputBorder baseBorder = outline(
      BorderSide(color: Colors.grey[400]!),
    );

    return SizedBox(
      width: width,
      child: Material(
        borderRadius: borderRadius,
        elevation: elevacao,
        child: TextFormField(
          textCapitalization: capitalization ?? TextCapitalization.none,
          textAlign: alinhamento,
          enabled: liberado,
          style: estilo,
          maxLines: lines,
          obscureText: oculto,
          cursorColor: _focusedBorderSide.color,
          controller: controle,
          inputFormatters: [mascara ?? allValues],
          autocorrect: false,
          keyboardType: tipoTeclado,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onEditingComplete: finishFunction,
          textInputAction: textInputButton,
          onTap: tapFunction,
          onChanged: mudeiTextoFunction,
          decoration: InputDecoration(
            labelStyle: _hintLabelStyle,
            labelText: mostrarHint ? hint : null,
            hintText: hint,
            hintStyle: _hintLabelStyle,
            fillColor: Colors.grey[50],
            filled: true,
            focusedBorder: outline(_focusedBorderSide),
            enabledBorder: baseBorder,
            errorBorder: outline(_errorBorderSide),
            border: baseBorder,
            disabledBorder: outline(
              BorderSide(color: disabledColor ?? Colors.grey[100]!),
            ),
            errorMaxLines: 3,
            suffixIcon: clear
                ? Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      canRequestFocus: false,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child: const Icon(
                        Icons.clear,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onTap: () {
                        controle.clear();
                        if (mascara is! FilteringTextInputFormatter) {
                          try {
                            (mascara as dynamic).clear();
                          } catch (_) {}
                        }
                        mudeiTextoFunction?.call('');
                      },
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
