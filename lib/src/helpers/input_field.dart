import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FilteringTextInputFormatter allValues =
    FilteringTextInputFormatter.allow(RegExp('.*'));

class InputField extends StatelessWidget {
  const InputField({
    Key? key,
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
  })  : estilo = estilo ?? const TextStyle(fontSize: 16),
        super(key: key);
  static const TextStyle _hintLabelStyle =
      TextStyle(fontSize: 16, color: Colors.grey);
  static const BorderSide _focusedBorderSide =
      BorderSide(color: Color.fromARGB(255, 0, 67, 0));
  static const BorderSide _errorBorderSide = BorderSide(color: Colors.red);

  final TextEditingController controle;
  final TextInputFormatter? mascara;
  final TextInputAction textInputButton;
  final TextInputType tipoTeclado;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final double width;
  final bool oculto;
  final VoidCallback? finishFunction;
  final bool clear;
  final VoidCallback? tapFunction;
  final int? lines;
  final double raio;
  final double elevacao;
  final TextStyle estilo;
  final ValueChanged<String>? mudeiTextoFunction;
  final bool mostrarHint;
  final bool liberado;
  final TextAlign alinhamento;
  final Color? disabledColor;
  final TextCapitalization? capitalization;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(raio);
    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey[400]!),
    );

    return SizedBox(
      width: width,
      child: Material(
        borderRadius: BorderRadius.circular(raio),
        elevation: elevacao,
        child: TextFormField(
          textCapitalization: capitalization ?? TextCapitalization.none,
          textAlign: alinhamento,
          enabled: liberado,
          style: estilo,
          maxLines: lines,
          obscureText: oculto,
          cursorColor: const Color.fromARGB(255, 0, 67, 0),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: _focusedBorderSide,
            ),
            enabledBorder: baseBorder,
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: _errorBorderSide,
            ),
            border: baseBorder,
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: disabledColor ?? Colors.grey[100]!),
            ),
            errorMaxLines: 3,
            suffixIcon: clear
                ? Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      canRequestFocus: false,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child:
                          const Icon(Icons.clear, color: Colors.grey, size: 20),
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
