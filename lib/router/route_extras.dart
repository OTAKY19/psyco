import 'package:flutter/foundation.dart';

import '../models/simulation_model.dart';
import '../services/exam_blanc_service.dart';

class QuizRouteExtra {
  final String? mode;
  final Map<String, dynamic>? categoryData;
  final Map<String, dynamic>? examConfig;
  final Map<String, dynamic>? subjectData;

  const QuizRouteExtra({
    this.mode,
    this.categoryData,
    this.examConfig,
    this.subjectData,
  });
}

class TestResultRouteExtra {
  final Map<String, dynamic>? testResults;
  final Map<String, dynamic>? paymentResult;

  const TestResultRouteExtra({
    this.testResults,
    this.paymentResult,
  });
}

class ExamResultRouteExtra {
  final ExamBlancResult? result;
  final Map<String, dynamic>? arguments;
  final Map<String, dynamic>? examResults;

  const ExamResultRouteExtra({
    this.result,
    this.arguments,
    this.examResults,
  });
}

class PaymentRouteExtra {
  final double amount;
  final String description;
  final dynamic onPaymentSuccess;
  final dynamic onPaymentCancel;

  const PaymentRouteExtra({
    required this.amount,
    required this.description,
    this.onPaymentSuccess,
    this.onPaymentCancel,
  });
}

class SimulationRouteExtra {
  final String userId;
  final SimulationModel? simulation;

  const SimulationRouteExtra({
    required this.userId,
    this.simulation,
  });
}

class ExamSessionExtra {
  final ExamBlancSession session;

  const ExamSessionExtra({required this.session});
}

class DemoExamRouteExtra {
  final VoidCallback? onDemoCompleted;
  final VoidCallback? onUpgradeNow;

  const DemoExamRouteExtra({
    this.onDemoCompleted,
    this.onUpgradeNow,
  });
}
