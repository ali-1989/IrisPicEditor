import 'package:flutter/material.dart';

class IconTextBtn extends StatefulWidget { //same Tab
  final double? width;
  final Color backColor;
  final Color iconColor;
  final Color textColor;
  final void Function()? onTap;
  final String? title;
  final IconData icon;

  const IconTextBtn({
    required this.icon,
    Key? key,
    this.onTap,
    this.title,
    this.width,
    this.backColor = Colors.black,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
  })
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return IconTextBtnState();
  }
}
///========================================================================================
class IconTextBtnState extends State<IconTextBtn>{
  late Color splashColor;

  @override
  Widget build(BuildContext context) {
    HSLColor hsl = HSLColor.fromColor(widget.backColor);
    splashColor = hsl.withHue(hsl.hue > 180? hsl.hue-6: hsl.hue+6).toColor();

    return Container(
      width: widget.width?? MediaQuery.of(context).size.width / 6,
      color: widget.backColor,
      child: Material(
        color: widget.backColor,
        clipBehavior: Clip.antiAlias,
        type: MaterialType.circle,

        child: InkWell(
          onTap: widget.onTap,
          splashColor: splashColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, color: widget.iconColor,),
              SizedBox(height: 4,),
              Text(widget.title?? ' ', style: TextStyle(color: widget.textColor),)
            ],
          ),
        ),
      ),
    );
  }
}