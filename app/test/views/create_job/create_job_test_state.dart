import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';

class CreateJobTestState extends CreateJobState {
  CreateJobTestState({required this.initialData});

  final CreateJobData initialData;

  @override
  CreateJobData build() => initialData;
}
