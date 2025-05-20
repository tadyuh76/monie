import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Account extends Equatable {
   String? id;
   String? user_id;
   String? name;
   String? type; // 'bank', 'cash', etc.
   double? balance;
   String? currency;
   bool? archived;
   int? color;
   bool pinned;
   int? transactionCount;

   Account({
     this.id,
     this.user_id,
     this.name,
     this.type,
     this.balance = 0.0,
     this.currency,
     this.archived,
     this.color,
     this.pinned = false,
     this.transactionCount,
  });

   Color getColor(){
     return Color(color ?? Colors.green.value);
   }


  @override
  List<Object?> get props => [
    id,
    user_id,
    name,
    type,
    balance,
    currency,
    archived,
    color,
    pinned,
    transactionCount,
  ];
}
