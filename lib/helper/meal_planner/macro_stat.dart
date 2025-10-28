import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


 class macrostat {
 static Widget _buildMacroStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}